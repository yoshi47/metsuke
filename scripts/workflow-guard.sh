#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# Detect git commit in potentially compound commands (&&, ;, ||)
# Uses awk for splitting (BSD sed doesn't interpret \n in replacements)
is_git_commit() {
  local cmd="$1"
  while IFS= read -r segment; do
    segment="${segment#"${segment%%[![:space:]]*}"}"
    [[ -z "$segment" ]] && continue
    # Match: git [global-flags] commit (but not git commit-graph etc.)
    if printf '%s\n' "$segment" | grep -qE '^\s*git(\s+(-[Cc]\s+\S+|--[a-z-]+=\S+|--[a-z-]+\s+\S+))*\s+commit(\s|$)'; then
      return 0
    fi
  done < <(printf '%s\n' "$cmd" | awk '{gsub(/&&|;|\|\|/,"\n"); print}')

  # Check user-configured aliases (e.g., git ci)
  local config_file
  config_file=$(metsuke_effective_config 2>/dev/null) || return 1
  local aliases
  aliases=$(jq -r '.commit_aliases // [] | .[]' "$config_file" 2>/dev/null) || return 1
  [[ -z "$aliases" ]] && return 1

  while IFS= read -r segment; do
    segment="${segment#"${segment%%[![:space:]]*}"}"
    [[ -z "$segment" ]] && continue
    while IFS= read -r pat; do
      [[ -z "$pat" ]] && continue
      if printf '%s\n' "$segment" | grep -qE "$pat"; then
        return 0
      fi
    done <<< "$aliases"
  done < <(printf '%s\n' "$cmd" | awk '{gsub(/&&|;|\|\|/,"\n"); print}')

  return 1
}

INPUT=$(cat)

# No config = not initialized
if ! metsuke_config_exists; then exit 0; fi

# Early exit: only care about commands containing "commit"
if ! echo "$INPUT" | grep -q 'commit'; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

metsuke_log "workflow-guard: session=${SESSION_ID} command=${COMMAND}"
metsuke_log "workflow-guard stdin: $(echo "$INPUT" | jq -c .)"

# Only block actual git commit commands, not grep/log matches
if ! is_git_commit "$COMMAND"; then
  exit 0
fi

# Skip check
if metsuke_is_skipped "$SESSION_ID"; then
  metsuke_log "workflow-guard: skipped"
  exit 0
fi

# Fail-closed: if config parsing fails, block the commit
checks_output=$(metsuke_checks_by_trigger "pre_commit") || {
  metsuke_log "ERROR: workflow-guard: failed to read checks, blocking commit as safety measure"
  cat <<EOF
{
  "decision": "block",
  "reason": "[metsuke] 設定の読み取りに失敗しました。config.json を確認してください。\n\n回避: /metsuke:skip-review または METSUKE_SKIP=1"
}
EOF
  exit 0
}

# No pre_commit checks configured
if [[ -z "$checks_output" ]]; then
  metsuke_log "workflow-guard: no pre_commit checks configured"
  exit 0
fi

# Collect all unsatisfied pre_commit checks
block_reasons=""

while IFS= read -r check; do
  [[ -z "$check" ]] && continue
  name=$(metsuke_check_field "$check" "name") || continue

  if ! metsuke_check "$SESSION_ID" "${name}-done"; then
    msg=$(metsuke_check_field "$check" "message") || continue
    action=$(metsuke_check_field "$check" "action") || action="remind"

    if [[ "$action" == "block" ]]; then
      if [[ -n "$block_reasons" ]]; then
        block_reasons="${block_reasons}\n"
      fi
      block_reasons="${block_reasons}${msg}"
    else
      metsuke_log "workflow-guard: remind (${name}): ${msg}"
    fi
  fi
done <<< "$checks_output"

# Block if any block checks are unsatisfied
if [[ -n "$block_reasons" ]]; then
  metsuke_log "workflow-guard: BLOCKED - checks not done"
  block_reasons="${block_reasons}\n\n回避: /metsuke:skip-review または METSUKE_SKIP=1"
  ESCAPED_REASON=$(printf '%b' "$block_reasons" | jq -Rs .)

  cat <<EOF
{
  "decision": "block",
  "reason": ${ESCAPED_REASON}
}
EOF
else
  metsuke_log "workflow-guard: all pre_commit checks passed"
fi

exit 0
