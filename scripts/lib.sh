#!/usr/bin/env bash
# metsuke - shared library

METSUKE_DIR="${TMPDIR:-/tmp}/metsuke"
METSUKE_LOG="${METSUKE_DIR}/debug.log"
METSUKE_CONFIG_DIR="${HOME}/.config/metsuke"
METSUKE_CONFIG="${METSUKE_CONFIG_DIR}/config.json"
METSUKE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METSUKE_DEFAULT_CONFIG="${METSUKE_LIB_DIR}/../config/default.json"

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

# Config helpers — user config takes precedence, then plugin default

# Returns the path to the effective config file (user config > plugin default)
metsuke_effective_config() {
  if [[ -f "$METSUKE_CONFIG" ]]; then
    echo "$METSUKE_CONFIG"
  elif [[ -f "$METSUKE_DEFAULT_CONFIG" ]]; then
    echo "$METSUKE_DEFAULT_CONFIG"
  else
    return 1
  fi
}

metsuke_config_exists() {
  metsuke_effective_config >/dev/null 2>&1
}

metsuke_config_get() {
  local key="$1"
  local default="${2:-}"
  local config_file
  config_file=$(metsuke_effective_config) || { echo "$default"; return; }
  local val
  val=$(jq -r "$key // empty" "$config_file" 2>/dev/null)
  if [[ -n "$val" ]]; then echo "$val"; return; fi
  echo "$default"
}

# Check helpers — generic checks array support

# Returns 0 on success, 1 on jq/parse failure.
# Callers should check the return code and fail-closed if needed.
metsuke_all_checks() {
  local config_file
  config_file=$(metsuke_effective_config) || return 0
  local output
  if ! output=$(jq -c '.checks // [] | .[] | select(.enabled != false)' "$config_file" 2>&1); then
    metsuke_log "ERROR: failed to parse config: $output"
    return 1
  fi
  printf '%s\n' "$output"
}

metsuke_checks_by_trigger() {
  local trigger="$1"
  local config_file
  config_file=$(metsuke_effective_config) || return 0
  local output
  if ! output=$(jq -c --arg t "$trigger" '.checks // [] | .[] | select(.enabled != false and .trigger == $t)' "$config_file" 2>&1); then
    metsuke_log "ERROR: failed to parse config: $output"
    return 1
  fi
  printf '%s\n' "$output"
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
