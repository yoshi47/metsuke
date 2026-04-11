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

# Collect checks matching current mode
show_reminders() {
  local trigger="$1"
  local checks_output
  checks_output=$(metsuke_checks_by_trigger "$trigger") || {
    metsuke_log "ERROR: workflow-reminder: failed to read checks for trigger=${trigger}"
    return
  }

  [[ -z "$checks_output" ]] && return

  while IFS= read -r check; do
    [[ -z "$check" ]] && continue
    name=$(metsuke_check_field "$check" "name") || continue

    if ! metsuke_check "$SESSION_ID" "${name}-done"; then
      action=$(metsuke_check_field "$check" "action") || {
        metsuke_log "WARNING: check '${name}' missing action field, defaulting to remind"
        action="remind"
      }
      if [[ "$action" == "block" ]]; then
        metsuke_log "WARNING: check '${name}' has action=block on trigger=${trigger}, falling back to remind"
      fi
      msg=$(metsuke_check_field "$check" "message") || continue
      echo "$msg"
    fi
  done <<< "$checks_output"
}

# Plan mode reminders
if [[ "$PERMISSION_MODE" == "plan" ]]; then
  show_reminders "plan_mode"
fi

exit 0
