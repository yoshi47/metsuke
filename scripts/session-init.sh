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

EFFECTIVE=$(metsuke_effective_config 2>/dev/null) || true

if [[ -z "$EFFECTIVE" ]]; then
  echo "[metsuke] ERROR: default config not found. Plugin may be corrupted."
elif ! jq -e '.' "$EFFECTIVE" >/dev/null 2>&1; then
  echo "[metsuke] ERROR: config.json が不正な JSON です。構文を確認してください。"
elif ! jq -e '.checks' "$EFFECTIVE" >/dev/null 2>&1; then
  echo "[metsuke] 設定ファイルが旧形式です。/metsuke:init を実行して新形式に移行してください。"
elif [[ "$EFFECTIVE" == "$METSUKE_CONFIG" ]]; then
  echo "[metsuke] Workflow tracking initialized."
else
  echo "[metsuke] Workflow tracking initialized (default config)."
fi
