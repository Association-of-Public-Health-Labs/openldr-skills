#!/usr/bin/env bash
# =============================================================================
# open-report.sh — OpenLDR Report Browser Helper
#
# Opens an HTML report file in the system default browser.
# Optionally copies the file to an output directory and/or renames it.
#
# Auto-detects the platform:
#   WSL   — wslview (wslu) or cmd.exe /c start
#   macOS — open
#   Linux — xdg-open
#
# Does NOT require database or API credentials.
#
# Usage:
#   ./open-report.sh <file.html>
#   ./open-report.sh <file.html> --output-dir <dir>
#   ./open-report.sh <file.html> --name <name>
#   ./open-report.sh --help
# =============================================================================

set -euo pipefail

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

show_help() {
  cat <<'HELP'
OpenLDR Report Browser Helper

Opens an HTML report file in the system default browser.
Optionally copies the file to an output directory and/or renames it.

USAGE:
  ./open-report.sh <file.html>
  ./open-report.sh <file.html> --output-dir <dir>
  ./open-report.sh <file.html> --name <name>
  ./open-report.sh <file.html> --output-dir <dir> --name <name>
  ./open-report.sh --help

ARGUMENTS:
  <file.html>            Path to the HTML report file to open

OPTIONS:
  --output-dir <dir>     Copy the report to this directory before opening
  --name <name>          Rename the file (adds .html extension automatically)
  --help, -h             Show this help message

PLATFORM SUPPORT:
  WSL    wslview (wslu) or cmd.exe /c start
  macOS  open
  Linux  xdg-open

EXAMPLES:
  # Open a report in the default browser
  ./open-report.sh report.html

  # Copy to ~/reports/ and open from there
  ./open-report.sh report.html --output-dir ~/reports

  # Copy, rename, and open
  ./open-report.sh /tmp/out.html --output-dir ~/reports --name vl-summary-2024
HELP
}

# ---------------------------------------------------------------------------
# Detect the platform and pick the browser-open command.
# ---------------------------------------------------------------------------
detect_open_cmd() {
  # WSL: /proc/version contains "microsoft" or "WSL"
  if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    if command -v wslview &>/dev/null; then
      echo "wslview"
    else
      echo "cmd.exe /c start"
    fi
    return 0
  fi

  # macOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo "open"
    return 0
  fi

  # Linux
  if command -v xdg-open &>/dev/null; then
    echo "xdg-open"
    return 0
  fi

  echo -e "${RED}Error: No browser-open command found.${NC}" >&2
  echo "Install one of: xdg-open (xdg-utils), wslview (wslu), or use macOS." >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
FILE_PATH=""
OUTPUT_DIR=""
RENAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    --output-dir)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Error: --output-dir requires a directory argument${NC}" >&2
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --name)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Error: --name requires a name argument${NC}" >&2
        exit 1
      fi
      RENAME="$2"
      shift 2
      ;;
    -*)
      echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
      show_help >&2
      exit 1
      ;;
    *)
      if [[ -n "$FILE_PATH" ]]; then
        echo -e "${RED}Error: Unexpected argument '$1' (file already set to '$FILE_PATH')${NC}" >&2
        exit 1
      fi
      FILE_PATH="$1"
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate input
# ---------------------------------------------------------------------------
if [[ -z "$FILE_PATH" ]]; then
  echo -e "${RED}Error: No HTML file specified${NC}" >&2
  echo "" >&2
  show_help >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo -e "${RED}Error: File not found: ${FILE_PATH}${NC}" >&2
  exit 1
fi

# Resolve to absolute path
FILE_PATH="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"

# ---------------------------------------------------------------------------
# Handle --output-dir: create dir and copy file there
# ---------------------------------------------------------------------------
if [[ -n "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
  OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

  # Determine destination filename
  if [[ -n "$RENAME" ]]; then
    # Add .html extension if not already present
    DEST_NAME="${RENAME%.html}.html"
  else
    DEST_NAME="$(basename "$FILE_PATH")"
  fi

  DEST_PATH="${OUTPUT_DIR}/${DEST_NAME}"
  cp "$FILE_PATH" "$DEST_PATH"
  FILE_PATH="$DEST_PATH"

elif [[ -n "$RENAME" ]]; then
  # --name without --output-dir: rename in the same directory
  DIR="$(dirname "$FILE_PATH")"
  DEST_NAME="${RENAME%.html}.html"
  DEST_PATH="${DIR}/${DEST_NAME}"
  cp "$FILE_PATH" "$DEST_PATH"
  FILE_PATH="$DEST_PATH"
fi

# ---------------------------------------------------------------------------
# Build file:// URL (handle WSL path conversion if needed)
# ---------------------------------------------------------------------------
FILE_URL="file://${FILE_PATH}"

# On WSL, convert Linux path to Windows path for the URL
if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  WIN_PATH="$(wslpath -w "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
  FILE_URL="file:///${WIN_PATH//\\//}"
fi

# ---------------------------------------------------------------------------
# Detect browser opener before printing success (fail early)
# ---------------------------------------------------------------------------
OPEN_CMD="$(detect_open_cmd)"

# ---------------------------------------------------------------------------
# Print path and URL (green if terminal)
# ---------------------------------------------------------------------------
echo -e "${GREEN}Report:${NC} ${FILE_PATH}"
echo -e "${GREEN}URL:${NC}    ${FILE_URL}"

# ---------------------------------------------------------------------------
# Open in browser
# ---------------------------------------------------------------------------
# cmd.exe /c start needs special quoting
if [[ "$OPEN_CMD" == "cmd.exe /c start" ]]; then
  cmd.exe /c start "" "$FILE_URL"
else
  $OPEN_CMD "$FILE_URL" 2>/dev/null &
fi
