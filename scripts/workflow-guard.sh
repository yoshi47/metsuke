#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

# No config = not initialized
if ! metsuke_config_exists; then exit 0; fi

# Early exit: only care about git commit
if ! echo "$INPUT" | grep -q '"commit"'; then
  exit 0
fi

# Check if impl_review is enabled
if ! metsuke_config_enabled '.impl_review.enabled'; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

metsuke_log "workflow-guard: session=${SESSION_ID} command=${COMMAND}"
metsuke_log "workflow-guard stdin: $(echo "$INPUT" | jq -c .)"

# Only block actual git commit commands, not grep matches
if ! echo "$COMMAND" | grep -qE '\bgit\b.*\bcommit\b'; then
  exit 0
fi

# Check if commit blocking is enabled
if [[ "$(metsuke_config_get '.impl_review.block_commit' 'true')" != "true" ]]; then
  exit 0
fi

# Skip check
if metsuke_is_skipped "$SESSION_ID"; then
  metsuke_log "workflow-guard: skipped"
  exit 0
fi

# Review check
if metsuke_check "$SESSION_ID" "pr-review-done"; then
  metsuke_log "workflow-guard: review done, allowing commit"
  exit 0
fi

# Block
metsuke_log "workflow-guard: BLOCKED - review not done"
REASON=$(metsuke_config_get '.impl_review.block_message' \
  "[metsuke] git commit blocked: レビュー未実施\npr-review-toolkit:review-pr を実行してください。\n省略するには /metsuke:skip-review を実行してください。")

ESCAPED_REASON=$(printf '%s' "$REASON" | jq -Rs .)

cat <<EOF
{
  "decision": "block",
  "reason": ${ESCAPED_REASON}
}
EOF
exit 0
