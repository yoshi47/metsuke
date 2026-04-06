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

# Extract agent identifiers - check multiple possible fields
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // ""')

metsuke_log "SubagentStop: agent_type=${AGENT_TYPE} agent_id=${AGENT_ID} subagent_type=${SUBAGENT_TYPE}"

ALL_FIELDS="${AGENT_TYPE} ${AGENT_ID} ${SUBAGENT_TYPE}"

# PR review detection
if metsuke_config_enabled '.impl_review.enabled'; then
  # Read patterns from config, fall back to default
  PATTERNS=$(metsuke_config_get '.impl_review.detection_patterns // [] | .[]' 'pr-review-toolkit')
  for pattern in $PATTERNS; do
    if echo "$ALL_FIELDS" | grep -qi "$pattern"; then
      metsuke_log "SubagentStop: PR review detected (pattern: ${pattern}), marking done"
      metsuke_mark "$SESSION_ID" "pr-review-done"
      break
    fi
  done
fi

# Plan review detection
if metsuke_config_enabled '.plan_review.enabled'; then
  PATTERNS=$(metsuke_config_get '.plan_review.detection_patterns // [] | .[]' 'plan-document-reviewer')
  for pattern in $PATTERNS; do
    if echo "$ALL_FIELDS" | grep -qi "$pattern"; then
      metsuke_log "SubagentStop: Plan review detected (pattern: ${pattern}), marking done"
      metsuke_mark "$SESSION_ID" "plan-review-done"
      break
    fi
  done
fi

exit 0
