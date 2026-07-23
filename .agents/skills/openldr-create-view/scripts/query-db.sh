#!/usr/bin/env bash
# =============================================================================
# query-db.sh — OpenLDR Database Query Helper
#
# Queries OpenLDRDict or OpenLDRData databases using sqlcmd or python3+pyodbc.
# Used by the openldr-create-view skill to discover panel codes,
# observation codes, and validate view definitions.
#
# Credentials are loaded from (first match wins):
#   1. .env in current working directory  (project-specific)
#   2. ~/.openldr.env                     (global fallback)
#   3. Shell environment variables        (from ~/.bashrc etc.)
#
# Required variables:
#   OPENLDR_DB_HOST     — SQL Server hostname (e.g., localhost, 192.168.1.100)
#   OPENLDR_DB_USER     — Database username
#   OPENLDR_DB_PASSWORD — Database password
#
# Optional variables:
#   OPENLDR_DB_DICT     — Dictionary database name (default: OpenLDRDict)
#   OPENLDR_DB_DATA     — Data database name (default: OpenLDRData)
#   OPENLDR_DB_PORT     — SQL Server port (default: 1433)
#
# Usage:
#   ./query-db.sh panels                    # List all panel codes
#   ./query-db.sh observations VIRAL        # List observation codes for a panel
#   ./query-db.sh query dict "SELECT ..."   # Run arbitrary query on dict DB
#   ./query-db.sh query data "SELECT ..."   # Run arbitrary query on data DB
#   ./query-db.sh test                      # Test database connectivity
#   ./query-db.sh --help                    # Show this help
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
    # Skip comments, blank lines, and lines without =
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    # Strip surrounding quotes and whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//' | xargs)
    # Only export if not already set (don't override shell env)
    if [ -z "${!key:-}" ]; then
      export "$key=$value"
    fi
  done < "$env_file"
}

# Load in priority order: project .env first (more specific), then global
load_env "${PWD}/.env"
load_env "${HOME}/.openldr.env"

# Defaults
DB_DICT="${OPENLDR_DB_DICT:-OpenLDRDict}"
DB_DATA="${OPENLDR_DB_DATA:-OpenLDRData}"
DB_PORT="${OPENLDR_DB_PORT:-1433}"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

show_help() {
  cat <<'HELP'
OpenLDR Database Query Helper

COMMANDS:
  panels                     List all distinct panel codes with descriptions
  observations <PANEL_CODE>  List observation codes for a specific panel
  query dict "<SQL>"         Run a SQL query against the dictionary database
  query data "<SQL>"         Run a SQL query against the data database
  test                       Test database connectivity

CREDENTIALS (loaded in order, first match wins):
  1. .env in current working directory   (project-specific)
  2. ~/.openldr.env                      (global fallback)
  3. Shell environment variables         (from ~/.bashrc etc.)

REQUIRED VARIABLES:
  OPENLDR_DB_HOST       SQL Server hostname
  OPENLDR_DB_USER       Database username
  OPENLDR_DB_PASSWORD   Database password

OPTIONAL VARIABLES:
  OPENLDR_DB_DICT       Dictionary database name (default: OpenLDRDict)
  OPENLDR_DB_DATA       Data database name (default: OpenLDRData)
  OPENLDR_DB_PORT       SQL Server port (default: 1433)

EXAMPLES:
  # List all panels
  ./query-db.sh panels

  # Get observation codes for the VIRAL panel
  ./query-db.sh observations VIRAL

  # Run a custom query on the dictionary database
  ./query-db.sh query dict "SELECT TOP 10 * FROM Facilities"

  # Test connectivity
  ./query-db.sh test
HELP
}

check_env() {
  local missing=0
  if [ -z "${OPENLDR_DB_HOST:-}" ]; then
    echo -e "${RED}Error: OPENLDR_DB_HOST is not set${NC}" >&2
    missing=1
  fi
  if [ -z "${OPENLDR_DB_USER:-}" ]; then
    echo -e "${RED}Error: OPENLDR_DB_USER is not set${NC}" >&2
    missing=1
  fi
  if [ -z "${OPENLDR_DB_PASSWORD:-}" ]; then
    echo -e "${RED}Error: OPENLDR_DB_PASSWORD is not set${NC}" >&2
    missing=1
  fi
  if [ "$missing" -eq 1 ]; then
    echo "" >&2
    echo "Create a .env file in your working directory or at ~/.openldr.env:" >&2
    echo "" >&2
    echo "  OPENLDR_DB_HOST=localhost" >&2
    echo "  OPENLDR_DB_USER=your_username" >&2
    echo "  OPENLDR_DB_PASSWORD=your_password" >&2
    echo "" >&2
    echo "Looked in: ${PWD}/.env, ${HOME}/.openldr.env" >&2
    exit 1
  fi

}

# ---------------------------------------------------------------------------
# Find the best available SQL client: sqlcmd (in PATH or common locations)
# or python3+pyodbc as fallback.
# ---------------------------------------------------------------------------
SQLCMD=""
QUERY_METHOD=""

find_query_method() {
  # Already found
  [ -n "$QUERY_METHOD" ] && return 0

  # Try sqlcmd in PATH
  if command -v sqlcmd &>/dev/null; then
    SQLCMD="sqlcmd"
    QUERY_METHOD="sqlcmd"
    return 0
  fi

  # Try common installation paths (mssql-tools18, mssql-tools)
  for path in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd; do
    if [ -x "$path" ]; then
      SQLCMD="$path"
      QUERY_METHOD="sqlcmd"
      return 0
    fi
  done

  # Fallback: python3 + pyodbc
  if python3 -c "import pyodbc" &>/dev/null; then
    QUERY_METHOD="pyodbc"
    return 0
  fi

  echo -e "${RED}Error: No SQL client available.${NC}" >&2
  echo "Install one of:" >&2
  echo "  - mssql-tools18: sudo apt install mssql-tools18" >&2
  echo "  - pyodbc:        pip install pyodbc" >&2
  exit 1
}

run_query() {
  local db="$1"
  local sql="$2"

  find_query_method

  if [ "$QUERY_METHOD" = "sqlcmd" ]; then
    "$SQLCMD" -S "${OPENLDR_DB_HOST},${DB_PORT}" \
      -U "${OPENLDR_DB_USER}" \
      -P "${OPENLDR_DB_PASSWORD}" \
      -d "$db" \
      -Q "$sql" \
      -s "|" -W -h -1 \
      -C 2>/dev/null
  else
    python3 -c "
import pyodbc, sys

# Try ODBC Driver 18 first, then 17
for driver in ['ODBC Driver 18 for SQL Server', 'ODBC Driver 17 for SQL Server']:
    try:
        conn = pyodbc.connect(
            f'DRIVER={{{driver}}};'
            f'SERVER=${OPENLDR_DB_HOST},${DB_PORT};'
            f'DATABASE={db};'
            f'UID=${OPENLDR_DB_USER};'
            f'PWD=${OPENLDR_DB_PASSWORD};'
            f'TrustServerCertificate=yes;',
            timeout=10
        )
        break
    except pyodbc.Error:
        continue
else:
    print('Error: Could not connect with any ODBC driver', file=sys.stderr)
    sys.exit(1)

cursor = conn.cursor()
cursor.execute('''${sql}''')

if cursor.description:
    for row in cursor.fetchall():
        print('|'.join(str(v).strip() if v is not None else 'NULL' for v in row))

conn.close()
" 2>/dev/null
  fi
}

cmd_test() {
  check_env
  find_query_method
  echo "Testing connection to ${OPENLDR_DB_HOST}:${DB_PORT}..."
  echo "Using: ${QUERY_METHOD}${SQLCMD:+ ($SQLCMD)}"

  if run_query "$DB_DICT" "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}OK${NC} — Connected to ${DB_DICT}"
  else
    echo -e "${RED}FAIL${NC} — Cannot connect to ${DB_DICT}" >&2
    exit 1
  fi

  if run_query "$DB_DATA" "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}OK${NC} — Connected to ${DB_DATA}"
  else
    echo -e "${RED}FAIL${NC} — Cannot connect to ${DB_DATA}" >&2
    exit 1
  fi

  echo -e "${GREEN}All connections successful.${NC}"
}

cmd_panels() {
  check_env
  run_query "$DB_DICT" "
    SELECT DISTINCT
      LIMSPanelCode,
      LIMSPanelDesc
    FROM [dbo].[LIMSPanelCodes]
    ORDER BY LIMSPanelCode
  "
}

cmd_observations() {
  local panel_code="${1:-}"
  if [ -z "$panel_code" ]; then
    echo -e "${RED}Error: Panel code is required${NC}" >&2
    echo "Usage: $0 observations <PANEL_CODE>" >&2
    exit 1
  fi

  check_env
  run_query "$DB_DICT" "
    SELECT DISTINCT
      LIMSObservationCode,
      LIMSObservationDesc
    FROM [dbo].[LIMSPanelCodes]
    WHERE LIMSPanelCode = '${panel_code}'
    ORDER BY LIMSObservationCode
  "
}

cmd_query() {
  local target="${1:-}"
  local sql="${2:-}"

  if [ -z "$target" ] || [ -z "$sql" ]; then
    echo -e "${RED}Error: Database target and SQL query are required${NC}" >&2
    echo "Usage: $0 query <dict|data> \"<SQL>\"" >&2
    exit 1
  fi

  check_env

  case "$target" in
    dict) run_query "$DB_DICT" "$sql" ;;
    data) run_query "$DB_DATA" "$sql" ;;
    *)
      echo -e "${RED}Error: Unknown target '$target'. Use 'dict' or 'data'.${NC}" >&2
      exit 1
      ;;
  esac
}

# Main dispatch
case "${1:-}" in
  panels)       cmd_panels ;;
  observations) cmd_observations "${2:-}" ;;
  query)        cmd_query "${2:-}" "${3:-}" ;;
  test)         cmd_test ;;
  --help|-h|"")  show_help ;;
  *)
    echo -e "${RED}Error: Unknown command '$1'${NC}" >&2
    show_help >&2
    exit 1
    ;;
esac
