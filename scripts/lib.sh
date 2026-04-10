#!/usr/bin/env bash
# metsuke - shared library

METSUKE_DIR="${TMPDIR:-/tmp}/metsuke"
METSUKE_LOG="${METSUKE_DIR}/debug.log"
METSUKE_CONFIG_DIR="${HOME}/.config/metsuke"
METSUKE_CONFIG="${METSUKE_CONFIG_DIR}/config.json"

metsuke_marker_path() { echo "${METSUKE_DIR}/${1}.${2}"; }
metsuke_mark()        { mkdir -p "$METSUKE_DIR"; touch "$(metsuke_marker_path "$1" "$2")"; }
metsuke_check()       { test -f "$(metsuke_marker_path "$1" "$2")"; }
metsuke_is_skipped()  { [[ -n "${METSUKE_SKIP:-}" ]] || test -f "$(metsuke_marker_path "$1" skip)"; }
metsuke_cleanup()     { find "$METSUKE_DIR" -maxdepth 1 -mmin +1440 -delete 2>/dev/null; }
metsuke_clear_session() { rm -f "${METSUKE_DIR}/${1}."* 2>/dev/null; }

metsuke_log() {
  mkdir -p "$METSUKE_DIR"
  echo "[$(date '+%H:%M:%S')] $*" >> "$METSUKE_LOG"
}

# Config helpers — fall back to defaults if config or key is missing
metsuke_config_get() {
  local key="$1"
  local default="${2:-}"
  if [[ -f "$METSUKE_CONFIG" ]]; then
    local val
    val=$(jq -r "$key // empty" "$METSUKE_CONFIG" 2>/dev/null)
    if [[ -n "$val" ]]; then
      echo "$val"
      return
    fi
  fi
  echo "$default"
}

metsuke_config_exists() {
  [[ -f "$METSUKE_CONFIG" ]]
}

# Check helpers — generic checks array support

# Returns 0 on success, 1 on jq/parse failure.
# Callers should check the return code and fail-closed if needed.
metsuke_all_checks() {
  if [[ -f "$METSUKE_CONFIG" ]]; then
    local output
    if ! output=$(jq -c '.checks // [] | .[] | select(.enabled != false)' "$METSUKE_CONFIG" 2>&1); then
      metsuke_log "ERROR: failed to parse config: $output"
      return 1
    fi
    printf '%s\n' "$output"
  fi
}

metsuke_checks_by_trigger() {
  local trigger="$1"
  if [[ -f "$METSUKE_CONFIG" ]]; then
    local output
    if ! output=$(jq -c --arg t "$trigger" '.checks // [] | .[] | select(.enabled != false and .trigger == $t)' "$METSUKE_CONFIG" 2>&1); then
      metsuke_log "ERROR: failed to parse config: $output"
      return 1
    fi
    printf '%s\n' "$output"
  fi
}

metsuke_check_field() {
  local val
  val=$(printf '%s\n' "$1" | jq -r ".$2 // empty" 2>/dev/null)
  if [[ -z "$val" || "$val" =~ ^[[:space:]]+$ ]]; then
    metsuke_log "WARNING: check missing or blank field '$2': $1"
    return 1
  fi
  if [[ "$2" == "name" && "$val" =~ [/[:space:]] ]]; then
    metsuke_log "WARNING: check name contains invalid characters: '$val'"
    return 1
  fi
  echo "$val"
}
