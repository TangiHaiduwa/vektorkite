# Provider Liveness API (Step 7)

This is a deploy-ready backend skeleton for the Provider app liveness/verification flow.

## Contract (matches provider app)

- `POST /liveness/sessions/start`
- `POST /liveness/sessions/{sessionId}/evaluate`
- `GET /liveness/sessions/{sessionId}`

Authentication:

- Cognito JWT bearer token (`Authorization: Bearer <access_token>`)
- `providerId` in request body must match JWT `sub`.

## What this skeleton does

1. Creates a liveness session in DynamoDB.
2. Evaluates ID-vs-selfie face match using Rekognition `CompareFaces`.
3. Stores a decision:
- `PASSED`
- `FAILED`
- `REVIEW`
4. Returns session status for mobile polling/fetch.

## Important limitation

This is a **backend skeleton**, not full Rekognition Face Liveness video flow yet.
For production-grade anti-spoof liveness, add:

1. `CreateFaceLivenessSession` + mobile SDK capture flow.
2. `GetFaceLivenessSessionResults`.
3. Optional face match against ID still done in this API.

## Deploy with SAM

From `backend/liveness_api`:

```bash
sam build
sam deploy --guided
```

Required parameters:

- `CognitoUserPoolId`
- `CognitoAppClientId`
- `AwsRegion`
- `VerificationBucketName`

## Wire Provider app

Run Provider app with:

```bash
flutter run --dart-define=LIVENESS_API_BASE_URL=https://<api-id>.execute-api.<region>.amazonaws.com/prod
```

## Security recommendations

1. Restrict CORS origins to your app domains.
2. Use least-privilege IAM and KMS encryption for buckets/tables.
3. Add CloudWatch alarms and structured logs.
4. Add rate limiting / WAF for API endpoints.
