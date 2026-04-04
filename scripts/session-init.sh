#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

metsuke_log "SessionStart: session_id=${SESSION_ID}"
metsuke_log "SessionStart stdin: $(echo "$INPUT" | jq -c .)"

metsuke_clear_session "$SESSION_ID"
metsuke_cleanup

echo "[metsuke] Workflow tracking initialized."
