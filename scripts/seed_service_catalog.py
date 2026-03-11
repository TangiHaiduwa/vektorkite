#!/usr/bin/env python3
"""Seed ServiceCategory and ServiceSubcategory into AppSync from JSON catalog.

Usage examples:
  python scripts/seed_service_catalog.py --username admin@example.com --password "YourPassword"
  python scripts/seed_service_catalog.py --id-token "<JWT>"

Environment alternatives:
  VK_SEED_USERNAME, VK_SEED_PASSWORD, VK_ID_TOKEN
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any
from urllib import request


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "amplify" / "backend" / "api" / "vektorkite" / "seed" / "services_catalog.json"
AMPLIFY_CONFIG_DART = ROOT / "lib" / "amplifyconfiguration.dart"


def parse_amplify_config(path: Path) -> dict[str, Any]:
    content = path.read_text(encoding="utf-8")
    match = re.search(r"const amplifyconfig = '''(.*)''';", content, flags=re.DOTALL)
    if not match:
        raise RuntimeError("Could not parse amplifyconfig from lib/amplifyconfiguration.dart")
    return json.loads(match.group(1))


def infer_region_from_endpoint(endpoint: str) -> str:
    # Example: https://abc.appsync-api.eu-north-1.amazonaws.com/graphql
    match = re.search(r"\.appsync-api\.([a-z0-9-]+)\.amazonaws\.com", endpoint)
    if not match:
        raise RuntimeError(f"Unable to infer region from endpoint: {endpoint}")
    return match.group(1)


def gql_call(endpoint: str, id_token: str, query: str, variables: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = json.dumps({"query": query, "variables": variables or {}}).encode("utf-8")
    req = request.Request(
        endpoint,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": id_token,
        },
        method="POST",
    )
    with request.urlopen(req, timeout=60) as response:
        body = response.read().decode("utf-8")
    parsed = json.loads(body)
    if parsed.get("errors"):
        raise RuntimeError(f"GraphQL error: {parsed['errors'][0].get('message')}")
    return parsed.get("data", {})


def get_id_token_via_cognito(
    region: str,
    client_id: str,
    username: str,
    password: str,
) -> str:
    try:
        import boto3  # type: ignore
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "boto3 is required for username/password auth. Install with: python -m pip install boto3"
        ) from exc

    client = boto3.client("cognito-idp", region_name=region)
    result = client.initiate_auth(
        ClientId=client_id,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={
            "USERNAME": username,
            "PASSWORD": password,
        },
    )
    auth_result = result.get("AuthenticationResult") or {}
    id_token = auth_result.get("IdToken")
    if not id_token:
        raise RuntimeError("Failed to obtain Cognito IdToken.")
    return id_token


LIST_SERVICE_CATEGORIES = """
query ListServiceCategories {
  listServiceCategories(limit: 1000) {
    items { id slug name }
  }
}
"""

SERVICE_SUBCATEGORIES_BY_CATEGORY = """
query ServiceSubcategoriesByCategory($categoryId: ID!) {
  serviceSubcategoriesByCategory(categoryId: $categoryId, limit: 1000) {
    items { id slug name }
  }
}
"""

CREATE_SERVICE_CATEGORY = """
mutation CreateServiceCategory($input: CreateServiceCategoryInput!) {
  createServiceCategory(input: $input) { id }
}
"""

CREATE_SERVICE_SUBCATEGORY = """
mutation CreateServiceSubcategory($input: CreateServiceSubcategoryInput!) {
  createServiceSubcategory(input: $input) { id }
}
"""


def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return re.sub(r"-+", "-", value).strip("-")


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed service catalog into AppSync.")
    parser.add_argument("--catalog", default=str(DEFAULT_CATALOG), help="Path to services_catalog.json")
    parser.add_argument("--endpoint", default=None, help="AppSync GraphQL endpoint")
    parser.add_argument("--region", default=None, help="AWS region")
    parser.add_argument("--user-pool-client-id", default=None, help="Cognito user pool app client id")
    parser.add_argument("--id-token", default=os.getenv("VK_ID_TOKEN"), help="Cognito IdToken")
    parser.add_argument("--username", default=os.getenv("VK_SEED_USERNAME"), help="Cognito username/email")
    parser.add_argument("--password", default=os.getenv("VK_SEED_PASSWORD"), help="Cognito password")
    args = parser.parse_args()

    config = parse_amplify_config(AMPLIFY_CONFIG_DART)
    endpoint = args.endpoint or config["api"]["plugins"]["awsAPIPlugin"]["vektorkite"]["endpoint"]
    region = args.region or infer_region_from_endpoint(endpoint)
    client_id = args.user_pool_client_id or config["auth"]["plugins"]["awsCognitoAuthPlugin"]["CognitoUserPool"][
        "Default"
    ]["AppClientId"]

    id_token = args.id_token
    if not id_token:
        if not args.username or not args.password:
            print("Missing auth. Provide --id-token OR --username and --password.", file=sys.stderr)
            return 2
        id_token = get_id_token_via_cognito(
            region=region,
            client_id=client_id,
            username=args.username,
            password=args.password,
        )

    catalog_path = Path(args.catalog)
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    categories = catalog.get("categories", [])
    if not categories:
        print("No categories found in catalog.", file=sys.stderr)
        return 2

    existing_categories_data = gql_call(endpoint, id_token, LIST_SERVICE_CATEGORIES)
    existing_categories_raw = existing_categories_data.get("listServiceCategories", {}).get("items", []) or []
    existing_categories = {
        (item.get("slug") or ""): item for item in existing_categories_raw if isinstance(item, dict)
    }

    created_categories = 0
    created_subcategories = 0

    for idx, category in enumerate(categories, start=1):
        cat_slug = category["slug"]
        cat_name = category["name"]
        cat_id = category.get("id") or cat_slug
        cat_sort_order = category.get("sortOrder", idx)

        category_record = existing_categories.get(cat_slug)
        if category_record is None:
            gql_call(
                endpoint,
                id_token,
                CREATE_SERVICE_CATEGORY,
                {
                    "input": {
                        "id": cat_id,
                        "name": cat_name,
                        "slug": cat_slug,
                        "sortOrder": cat_sort_order,
                        "isActive": True,
                    }
                },
            )
            created_categories += 1
            category_id = cat_id
        else:
            category_id = category_record["id"]

        existing_subs_data = gql_call(
            endpoint,
            id_token,
            SERVICE_SUBCATEGORIES_BY_CATEGORY,
            {"categoryId": category_id},
        )
        existing_subs_raw = existing_subs_data.get("serviceSubcategoriesByCategory", {}).get("items", []) or []
        existing_sub_slugs = {
            (item.get("slug") or "") for item in existing_subs_raw if isinstance(item, dict)
        }

        for sub_index, sub_name in enumerate(category.get("subcategories", []), start=1):
            sub_slug = slugify(sub_name)
            if sub_slug in existing_sub_slugs:
                continue
            sub_id = f"{category_id}-{sub_slug}"
            gql_call(
                endpoint,
                id_token,
                CREATE_SERVICE_SUBCATEGORY,
                {
                    "input": {
                        "id": sub_id,
                        "categoryId": category_id,
                        "name": sub_name,
                        "slug": sub_slug,
                        "sortOrder": sub_index,
                        "isActive": True,
                    }
                },
            )
            created_subcategories += 1

    print("Seed complete.")
    print(f"Created categories: {created_categories}")
    print(f"Created subcategories: {created_subcategories}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
