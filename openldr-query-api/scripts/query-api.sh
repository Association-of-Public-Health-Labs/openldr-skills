#!/usr/bin/env bash
# =============================================================================
# query-api.sh — OpenLDR Analytics API Query Helper
#
# Authenticates with the OpenLDR API and executes endpoint queries.
# Used by the openldr-query-api skill to execute API calls.
#
# Credentials are loaded from (first match wins):
#   1. .env in current working directory  (project-specific)
#   2. ~/.openldr.env                     (global fallback)
#   3. Shell environment variables        (from ~/.bashrc etc.)
#
# Required variables:
#   OPENLDR_API_URL      — API base URL (default: https://dev.openldr.org.mz)
#   OPENLDR_API_USER     — API username
#   OPENLDR_API_PASSWORD — API password
#
# Usage:
#   ./query-api.sh login                           # Get JWT token
#   ./query-api.sh get "/hiv/vl/summary/header_indicators/?interval_dates=2024-01-01&interval_dates=2024-12-31"
#   ./query-api.sh get-noauth "/dict/facilities/"  # No-auth endpoints (dict)
#   ./query-api.sh test                            # Test API connectivity
#   ./query-api.sh --help                          # Show help
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Load .env — current working directory first, then global fallback.
# Only sets variables that are NOT already set in the environment,
# so shell env vars and project .env can coexist without conflict.
# ---------------------------------------------------------------------------
load_env() {
  local env_file="$1"
  [ -f "$env_file" ] || return 0
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//' | xargs)
    if [ -z "${!key:-}" ]; then
      export "$key=$value"
    fi
  done < "$env_file"
}

load_env "${PWD}/.env"
load_env "${HOME}/.openldr.env"

API_URL="${OPENLDR_API_URL:-https://dev.openldr.org.mz}"

# Colors
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

show_help() {
  cat <<'HELP'
OpenLDR Analytics API Query Helper

COMMANDS:
  login                    Authenticate and print JWT token
  get "<endpoint>?params"  Authenticate and GET an endpoint (with auth)
  get-noauth "<endpoint>"  GET an endpoint without authentication (dict endpoints)
  test                     Test API connectivity and authentication

CREDENTIALS (loaded in order, first match wins):
  1. .env in current working directory   (project-specific)
  2. ~/.openldr.env                      (global fallback)
  3. Shell environment variables         (from ~/.bashrc etc.)

REQUIRED VARIABLES:
  OPENLDR_API_URL       API base URL (default: https://dev.openldr.org.mz)
  OPENLDR_API_USER      API username (required for authenticated endpoints)
  OPENLDR_API_PASSWORD  API password (required for authenticated endpoints)

EXAMPLES:
  # Test connectivity
  ./query-api.sh test

  # Get VL summary indicators for 2024
  ./query-api.sh get "/hiv/vl/summary/header_indicators/?interval_dates=2024-01-01&interval_dates=2024-12-31"

  # Get VL suppression by province for Gaza
  ./query-api.sh get "/hiv/vl/summary/suppression_by_province/?interval_dates=2024-01-01&interval_dates=2024-12-31&province=Gaza"

  # Get facilities (no auth needed)
  ./query-api.sh get-noauth "/dict/facilities/"

  # Get TB positivity by month for Maputo
  ./query-api.sh get "/tb/gx/summary/positivity_by_month/?interval_dates=2024-01-01&interval_dates=2024-12-31&province=Maputo"

  # EID tested samples for POC labs
  ./query-api.sh get "/hiv/eid/laboratories/tested_samples/?interval_dates=2024-01-01&interval_dates=2024-12-31&lab_type=poc"
HELP
}

check_auth_env() {
  local missing=0
  if [ -z "${OPENLDR_API_USER:-}" ]; then
    echo -e "${RED}Error: OPENLDR_API_USER is not set${NC}" >&2
    missing=1
  fi
  if [ -z "${OPENLDR_API_PASSWORD:-}" ]; then
    echo -e "${RED}Error: OPENLDR_API_PASSWORD is not set${NC}" >&2
    missing=1
  fi
  if [ "$missing" -eq 1 ]; then
    echo "" >&2
    echo "Create a .env file in your working directory or at ~/.openldr.env:" >&2
    echo "" >&2
    echo "  OPENLDR_API_URL=https://dev.openldr.org.mz" >&2
    echo "  OPENLDR_API_USER=your_username" >&2
    echo "  OPENLDR_API_PASSWORD=your_password" >&2
    echo "" >&2
    echo "Looked in: ${PWD}/.env, ${HOME}/.openldr.env" >&2
    exit 1
  fi
}

get_token() {
  check_auth_env

  local response
  response=$(curl -s -X POST "${API_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${OPENLDR_API_USER}\", \"password\": \"${OPENLDR_API_PASSWORD}\"}")

  local token
  token=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

  if [ -z "$token" ]; then
    local msg
    msg=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','Unknown error'))" 2>/dev/null)
    echo -e "${RED}Authentication failed: ${msg}${NC}" >&2
    exit 1
  fi

  echo "$token"
}

cmd_login() {
  local token
  token=$(get_token)
  echo "$token"
}

cmd_get() {
  local endpoint="${1:-}"
  if [ -z "$endpoint" ]; then
    echo -e "${RED}Error: Endpoint path is required${NC}" >&2
    echo "Usage: $0 get \"/hiv/vl/summary/header_indicators/?params\"" >&2
    exit 1
  fi

  local token
  token=$(get_token)

  local response
  local http_code
  response=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}${endpoint}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json")

  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" = "401" ]; then
    echo -e "${YELLOW}Token expired, re-authenticating...${NC}" >&2
    token=$(get_token)
    response=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}${endpoint}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json")
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
  fi

  if [ "$http_code" != "200" ]; then
    echo -e "${RED}HTTP ${http_code}${NC}" >&2
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    exit 1
  fi

  echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
}

cmd_get_noauth() {
  local endpoint="${1:-}"
  if [ -z "$endpoint" ]; then
    echo -e "${RED}Error: Endpoint path is required${NC}" >&2
    echo "Usage: $0 get-noauth \"/dict/facilities/\"" >&2
    exit 1
  fi

  local response
  response=$(curl -s -X GET "${API_URL}${endpoint}" \
    -H "Content-Type: application/json")

  echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
}

cmd_test() {
  echo "Testing API at ${API_URL}..."

  # Test connectivity (dict endpoints don't need auth)
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/dict/facilities/" 2>/dev/null)

  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}OK${NC} — API reachable (dict endpoint returned 200)"
  else
    echo -e "${RED}FAIL${NC} — API unreachable (HTTP ${http_code})" >&2
    exit 1
  fi

  # Test authentication if env vars are set
  if [ -n "${OPENLDR_API_USER:-}" ] && [ -n "${OPENLDR_API_PASSWORD:-}" ]; then
    local token
    token=$(get_token 2>/dev/null) && \
      echo -e "${GREEN}OK${NC} — Authentication successful" || \
      echo -e "${RED}FAIL${NC} — Authentication failed" >&2
  else
    echo -e "${YELLOW}SKIP${NC} — Auth not tested (OPENLDR_API_USER/PASSWORD not set)"
  fi
}

# Main dispatch
case "${1:-}" in
  login)      cmd_login ;;
  get)        cmd_get "${2:-}" ;;
  get-noauth) cmd_get_noauth "${2:-}" ;;
  test)       cmd_test ;;
  --help|-h|"") show_help ;;
  *)
    echo -e "${RED}Error: Unknown command '$1'${NC}" >&2
    show_help >&2
    exit 1
    ;;
esac
