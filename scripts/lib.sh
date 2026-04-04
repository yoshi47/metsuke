#!/usr/bin/env bash
# metsuke - shared library

METSUKE_DIR="/tmp/metsuke"
METSUKE_LOG="${METSUKE_DIR}/debug.log"

metsuke_marker_path() { echo "${METSUKE_DIR}/${1}.${2}"; }
metsuke_mark()        { mkdir -p "$METSUKE_DIR"; touch "$(metsuke_marker_path "$1" "$2")"; }
metsuke_check()       { test -f "$(metsuke_marker_path "$1" "$2")"; }
metsuke_is_skipped()  { [[ -n "${METSUKE_SKIP:-}" ]] || test -f "$(metsuke_marker_path "$1" skip)"; }
metsuke_cleanup()     { find "$METSUKE_DIR" -maxdepth 1 -mtime +1 -delete 2>/dev/null; }
metsuke_clear_session() { rm -f "${METSUKE_DIR}/${1}."* 2>/dev/null; }

metsuke_log() {
  mkdir -p "$METSUKE_DIR"
  echo "[$(date '+%H:%M:%S')] $*" >> "$METSUKE_LOG"
}
