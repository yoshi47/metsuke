#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

# No config = not initialized
if ! metsuke_config_exists; then exit 0; fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Log full payload for spike investigation
metsuke_log "SubagentStop: session=${SESSION_ID}"
metsuke_log "SubagentStop stdin: $(echo "$INPUT" | jq -c .)"

# SubagentStop payload fields (observed via debug logging):
# - .agent_type: not reliably present in all payloads
# - .agent_id: not reliably present in all payloads
# - .subagent_type: agent type classification (e.g., "pr-review-toolkit:code-reviewer")
#
# Strategy: concatenate all fields and substring-match against detection_patterns.
# Over-matching (false positive → marks done too early) is safer than under-matching
# (false negative → check never clears → permanent block).
# Run /metsuke:status and check debug.log to verify actual payload format.
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // ""')

metsuke_log "SubagentStop: agent_type=${AGENT_TYPE} agent_id=${AGENT_ID} subagent_type=${SUBAGENT_TYPE}"

ALL_FIELDS="${AGENT_TYPE} ${AGENT_ID} ${SUBAGENT_TYPE}"

# Check all enabled checks for detection pattern matches
checks_output=$(metsuke_all_checks) || {
  metsuke_log "ERROR: workflow-tracker: failed to read checks"
  exit 0
}

while IFS= read -r check; do
  [[ -z "$check" ]] && continue
  name=$(metsuke_check_field "$check" "name") || continue

  # Iterate detection_patterns
  patterns=$(printf '%s\n' "$check" | jq -r '.detection_patterns // [] | .[]' 2>/dev/null) || {
    metsuke_log "ERROR: failed to extract detection_patterns for check '${name}'"
    continue
  }

  while IFS= read -r pattern; do
    if [[ -n "$pattern" ]] && printf '%s\n' "$ALL_FIELDS" | grep -qiF "$pattern"; then
      metsuke_log "SubagentStop: check '${name}' detected (pattern: ${pattern}), marking done"
      metsuke_mark "$SESSION_ID" "${name}-done"
      break
    fi
  done <<< "$patterns"
done <<< "$checks_output"

exit 0
