#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Log full payload for spike investigation
metsuke_log "SubagentStop: session=${SESSION_ID}"
metsuke_log "SubagentStop stdin: $(echo "$INPUT" | jq -c .)"

# Extract agent identifiers - check multiple possible fields
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // ""')

metsuke_log "SubagentStop: agent_type=${AGENT_TYPE} agent_id=${AGENT_ID} subagent_type=${SUBAGENT_TYPE}"

# Check all possible fields for pr-review-toolkit pattern
ALL_FIELDS="${AGENT_TYPE} ${AGENT_ID} ${SUBAGENT_TYPE}"

if echo "$ALL_FIELDS" | grep -qi 'pr-review-toolkit'; then
  metsuke_log "SubagentStop: PR review detected, marking done"
  metsuke_mark "$SESSION_ID" "pr-review-done"
fi

if echo "$ALL_FIELDS" | grep -qi 'plan-document-reviewer'; then
  metsuke_log "SubagentStop: Plan review detected, marking done"
  metsuke_mark "$SESSION_ID" "plan-review-done"
fi

exit 0
