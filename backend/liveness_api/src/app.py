import json
import os
import time
import uuid
from decimal import Decimal
from typing import Any, Dict, Tuple

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])
rekognition = boto3.client("rekognition", region_name=os.environ.get("AWS_REGION"))

VERIFICATION_BUCKET = os.environ["VERIFICATION_BUCKET"]
SIMILARITY_THRESHOLD = float(os.environ.get("SIMILARITY_THRESHOLD", "85"))


def start_session(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
  provider_sub = _extract_sub(event)
  payload = _body(event)
  provider_id = _require_str(payload, "providerId")
  id_document_key = _require_str(payload, "idDocumentKey")
  selfie_key = _require_str(payload, "selfieKey")

  if provider_id != provider_sub:
    return _response(403, {"message": "providerId must match authenticated user."})

  session_id = str(uuid.uuid4())
  now = int(time.time())
  item = {
      "sessionId": session_id,
      "providerId": provider_id,
      "idDocumentKey": id_document_key,
      "selfieKey": selfie_key,
      "decision": "PENDING",
      "score": Decimal("0"),
      "reason": "Session created",
      "createdAt": now,
      "updatedAt": now,
      "ttl": now + 60 * 60 * 24 * 30,
  }
  table.put_item(Item=item)
  return _response(
      200,
      {
          "sessionId": session_id,
          "decision": "PENDING",
          "message": "Session created",
      },
  )


def evaluate_session(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
  provider_sub = _extract_sub(event)
  session_id = _path_param(event, "sessionId")
  payload = _body(event)

  provider_id = _require_str(payload, "providerId")
  if provider_id != provider_sub:
    return _response(403, {"message": "providerId must match authenticated user."})

  session = _get_session_owned(session_id, provider_id)
  if session is None:
    return _response(404, {"message": "Session not found."})

  id_document_key = session["idDocumentKey"]
  selfie_key = session["selfieKey"]

  try:
    similarity, face_confidence = _compare_faces(id_document_key, selfie_key)
    decision, reason = _decision(similarity, face_confidence)
  except ClientError as error:
    _update_session(
      session_id,
      provider_id,
      decision="REVIEW",
      score=0,
      reason=f"Rekognition error: {error.response.get('Error', {}).get('Message', 'unknown')}",
    )
    return _response(200, {"sessionId": session_id, "decision": "REVIEW", "score": 0})

  _update_session(
      session_id,
      provider_id,
      decision=decision,
      score=similarity,
      reason=reason,
  )
  return _response(
      200,
      {
          "sessionId": session_id,
          "decision": decision,
          "score": similarity,
          "reason": reason,
      },
  )


def get_session(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
  provider_sub = _extract_sub(event)
  session_id = _path_param(event, "sessionId")

  session = _get_session_owned(session_id, provider_sub)
  if session is None:
    return _response(404, {"message": "Session not found."})

  return _response(
      200,
      {
          "sessionId": session["sessionId"],
          "providerId": session["providerId"],
          "decision": session.get("decision", "PENDING"),
          "score": float(session.get("score", 0)),
          "reason": session.get("reason"),
          "updatedAt": session.get("updatedAt"),
      },
  )


def _compare_faces(id_document_key: str, selfie_key: str) -> Tuple[float, float]:
  response = rekognition.compare_faces(
      SimilarityThreshold=0,
      SourceImage={"S3Object": {"Bucket": VERIFICATION_BUCKET, "Name": id_document_key}},
      TargetImage={"S3Object": {"Bucket": VERIFICATION_BUCKET, "Name": selfie_key}},
  )
  matches = response.get("FaceMatches", [])
  similarity = 0.0
  if matches:
    similarity = max(float(match.get("Similarity", 0)) for match in matches)

  detect = rekognition.detect_faces(
      Image={"S3Object": {"Bucket": VERIFICATION_BUCKET, "Name": selfie_key}},
      Attributes=["DEFAULT"],
  )
  face_details = detect.get("FaceDetails", [])
  face_confidence = 0.0
  if face_details:
    face_confidence = float(face_details[0].get("Confidence", 0))

  return similarity, face_confidence


def _decision(similarity: float, face_confidence: float) -> Tuple[str, str]:
  # This is a backend skeleton decision rule and not full Rekognition Face Liveness.
  if similarity >= SIMILARITY_THRESHOLD and face_confidence >= 90:
    return "PASSED", "Face similarity and selfie quality passed threshold."
  if similarity < 60:
    return "FAILED", "Face similarity too low."
  return "REVIEW", "Manual review required."


def _get_session_owned(session_id: str, provider_id: str) -> Dict[str, Any] | None:
  result = table.get_item(Key={"sessionId": session_id})
  item = result.get("Item")
  if item is None:
    return None
  if item.get("providerId") != provider_id:
    return None
  return item


def _update_session(
    session_id: str,
    provider_id: str,
    *,
    decision: str,
    score: float,
    reason: str,
) -> None:
  now = int(time.time())
  table.update_item(
      Key={"sessionId": session_id},
      UpdateExpression=(
          "SET #decision = :decision, #score = :score, #reason = :reason, #updatedAt = :updatedAt"
      ),
      ConditionExpression="providerId = :providerId",
      ExpressionAttributeNames={
          "#decision": "decision",
          "#score": "score",
          "#reason": "reason",
          "#updatedAt": "updatedAt",
      },
      ExpressionAttributeValues={
          ":decision": decision,
          ":score": Decimal(str(score)),
          ":reason": reason,
          ":updatedAt": now,
          ":providerId": provider_id,
      },
  )


def _extract_sub(event: Dict[str, Any]) -> str:
  claims = (
      event.get("requestContext", {})
      .get("authorizer", {})
      .get("jwt", {})
      .get("claims", {})
  )
  sub = claims.get("sub")
  if not sub:
    raise PermissionError("Unauthorized")
  return sub


def _body(event: Dict[str, Any]) -> Dict[str, Any]:
  raw = event.get("body")
  if not raw:
    return {}
  try:
    return json.loads(raw)
  except json.JSONDecodeError:
    return {}


def _require_str(payload: Dict[str, Any], key: str) -> str:
  value = payload.get(key)
  if not isinstance(value, str) or not value.strip():
    raise ValueError(f"{key} is required")
  return value.strip()


def _path_param(event: Dict[str, Any], name: str) -> str:
  params = event.get("pathParameters") or {}
  value = params.get(name)
  if not value:
    raise ValueError(f"Path parameter {name} is required.")
  return value


def _response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
  return {
      "statusCode": status_code,
      "headers": {
          "Content-Type": "application/json",
      },
      "body": json.dumps(body),
  }
