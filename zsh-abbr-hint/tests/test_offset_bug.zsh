#!/usr/bin/env zsh
# tests/test_offset_bug.zsh — Regression tests for the (i) vs (I) byte-offset bug
#
# Confirms that _zah_redraw appends the green region_highlight span over the
# RIGHTMOST (cursor) occurrence of cmd_word in buf_pre, not an earlier substring
# that happens to match.
#
# Confirmed failing cases before fix:
#   • BUFFER='false; ls', CURSOR=9, abbr 'ls':
#       (i) returns offset 2 (inside "false"), correct answer is 7.
#   • BUFFER='Gx G', CURSOR=4, global abbr 'G':
#       (i) returns offset 0 (the 'G' in 'Gx'), correct answer is 3.
#
# Run from ~/dotfiles:
#   zsh zsh-abbr-hint/tests/test_offset_bug.zsh
#
# Exit code: 0 on all PASS, non-zero on any FAIL.

emulate -LR zsh
setopt NO_GLOBAL_RCS

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
_zah_test_dir="${0:a:h}"
_zah_plugin="${_zah_test_dir:h}/.config/zsh/zsh-abbr-hint.plugin.zsh"

source "${_zah_test_dir}/lib.zsh"
zah_require_file "$_zah_plugin"

# ---------------------------------------------------------------------------
# Helper: extract start/end from the last region_highlight entry containing
# the green marker "#a6e3a1".
# Sets REPLY to "start end" if found, or "NOT_FOUND" otherwise.
# ---------------------------------------------------------------------------
_zah_green_span() {
  local span
  local found="NOT_FOUND"
  for span in "${region_highlight[@]}"; do
    [[ "$span" == *"#a6e3a1"* ]] && found="$span"
  done
  # Extract just "start end" (first two whitespace-delimited tokens)
  REPLY="${found%% fg=*}"
}

# ---------------------------------------------------------------------------
# Sub-case A: BUFFER='false; ls', CURSOR=9
#   Regular abbr 'ls'.  The word 'ls' also appears as a substring of 'false'
#   at byte offset 2 (f-a-l-s-e → 'ls' at positions 3..4 in 1-based, i.e.
#   0-based offset 2..4).
#   The cursor word 'ls' is at 0-based offset 7..9.
#   The correct green span must be "7 9", not "2 4".
# ---------------------------------------------------------------------------
print -r -- "--- Sub-case A: 'false; ls' — abbr 'ls' at tail, not inside 'false' ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"
  source "$_zah_plugin"

  # Seed regular abbreviation for 'ls'.
  typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS
  local k='ls' v='eza --icons'
  ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}

  # Stub zle() to suppress "not a ZLE command" errors.
  zle() { : }

  # Simulate ZLE state: user typed 'false; ls', cursor at end.
  typeset -g  BUFFER='false; ls'
  typeset -gi CURSOR=${#BUFFER}   # = 9
  typeset -a  region_highlight=()

  _zah_redraw 2>/dev/null

  # Extract the green span start/end.
  _zah_green_span
  local span_tokens=( ${=REPLY} )
  local span_start="${span_tokens[1]}"
  local span_end="${span_tokens[2]}"

  zah_assert_true "Sub-case A: a green span was appended" \
    test "$REPLY" != "NOT_FOUND"

  zah_assert_eq "Sub-case A: green span start is 7 (the tail 'ls'), not 2 (inside 'false')" \
    "7" "$span_start"

  zah_assert_eq "Sub-case A: green span end is 9" \
    "9" "$span_end"

  zah_finish
)
local subA_rc=$?
(( subA_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Sub-case B: BUFFER='Gx G', CURSOR=4
#   Global abbr 'G'.  The character 'G' also appears at offset 0 (in 'Gx').
#   The cursor word 'G' is at 0-based offset 3..4.
#   The correct green span must be "3 4", not "0 1".
# ---------------------------------------------------------------------------
print -r -- "--- Sub-case B: 'Gx G' — global abbr 'G' at tail, not inside 'Gx' ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"
  source "$_zah_plugin"

  # Seed global abbreviation for 'G'.
  typeset -gA ABBR_GLOBAL_USER_ABBREVIATIONS
  local kg='G' vg='| grep'
  ABBR_GLOBAL_USER_ABBREVIATIONS[${(qqq)kg}]=${(qqq)vg}

  # Stub zle().
  zle() { : }

  # Simulate ZLE state: user typed 'Gx G', cursor at end.
  typeset -g  BUFFER='Gx G'
  typeset -gi CURSOR=${#BUFFER}   # = 4
  typeset -a  region_highlight=()

  _zah_redraw 2>/dev/null

  _zah_green_span
  local span_tokens=( ${=REPLY} )
  local span_start="${span_tokens[1]}"
  local span_end="${span_tokens[2]}"

  zah_assert_true "Sub-case B: a green span was appended" \
    test "$REPLY" != "NOT_FOUND"

  zah_assert_eq "Sub-case B: green span start is 3 (the tail 'G'), not 0 (inside 'Gx')" \
    "3" "$span_start"

  zah_assert_eq "Sub-case B: green span end is 4" \
    "4" "$span_end"

  zah_finish
)
local subB_rc=$?
(( subB_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Finish
# ---------------------------------------------------------------------------
zah_finish; exit $?
