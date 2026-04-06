#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

# No config = not initialized
if ! metsuke_config_exists; then exit 0; fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // ""')

metsuke_log "UserPromptSubmit: session=${SESSION_ID} mode=${PERMISSION_MODE}"

# Skip check
if metsuke_is_skipped "$SESSION_ID"; then
  exit 0
fi

# Plan mode reminder
if [[ "$PERMISSION_MODE" == "plan" ]]; then
  if metsuke_config_enabled '.plan_review.enabled'; then
    if ! metsuke_check "$SESSION_ID" "plan-review-done"; then
      REMINDER=$(metsuke_config_get '.plan_review.reminder_message' \
        "[metsuke] プラン作成後は plan-document-reviewer でレビューしてからユーザーに提示してください。")
      echo "$REMINDER"
    fi
  fi
fi

exit 0
