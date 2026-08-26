#!/usr/bin/env bash
# Logs into an ECW backend (email/password) and mints an API key for X-API-Key auth.
#
# Usage:
#   ECW_EMAIL=you@example.com ECW_PASSWORD=secret ./scripts/get_dev_api_key.sh
#   ./scripts/get_dev_api_key.sh --email you@example.com   # prompts for password
#
# Env vars:
#   ECW_BACKEND_URL   Backend base URL (default: https://api-dev.edgebench.io)
#   ECW_EMAIL         Login email (or pass --email)
#   ECW_PASSWORD      Login password (or you'll be prompted, hidden input)
#   ECW_KEY_NAME      Label for the generated key (default: dev-cli-<timestamp>)
#
# Prints only the resulting API key to stdout; everything else goes to stderr,
# so this is safe to use as: export ECW_API_KEY=$(./scripts/get_dev_api_key.sh)

set -euo pipefail

BACKEND_URL="${ECW_BACKEND_URL:-https://api-dev.edgebench.io}"
EMAIL="${ECW_EMAIL:-}"
PASSWORD="${ECW_PASSWORD:-}"
KEY_NAME="${ECW_KEY_NAME:-dev-cli-$(date +%s)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --backend-url)
      BACKEND_URL="$2"
      shift 2
      ;;
    --key-name)
      KEY_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$EMAIL" ]; then
  read -r -p "ECW email: " EMAIL
fi

if [ -z "$PASSWORD" ]; then
  read -r -s -p "ECW password: " PASSWORD
  echo >&2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not found on PATH." >&2
  exit 1
fi

BACKEND_URL="${BACKEND_URL%/}"

echo "Logging in to ${BACKEND_URL} as ${EMAIL}..." >&2

LOGIN_PAYLOAD=$(jq -n --arg email "$EMAIL" --arg password "$PASSWORD" \
  '{email: $email, password: $password}')

LOGIN_RESPONSE=$(curl --fail --silent --show-error \
  --request POST \
  --header "Content-Type: application/json" \
  --data "$LOGIN_PAYLOAD" \
  "${BACKEND_URL}/auth/jwt/login")

JWT=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')
if [ -z "$JWT" ]; then
  echo "Login did not return a token. Response: $LOGIN_RESPONSE" >&2
  exit 1
fi

echo "Login OK, generating API key named '${KEY_NAME}'..." >&2

KEY_RESPONSE=$(curl --fail --silent --show-error \
  --request POST \
  --header "Authorization: Bearer ${JWT}" \
  --get \
  --data-urlencode "name=${KEY_NAME}" \
  "${BACKEND_URL}/generate-api-key")

API_KEY=$(echo "$KEY_RESPONSE" | jq -r '.api_key // empty')
if [ -z "$API_KEY" ]; then
  echo "API key generation did not return api_key. Response: $KEY_RESPONSE" >&2
  exit 1
fi

echo "API key generated." >&2
echo "$API_KEY"
