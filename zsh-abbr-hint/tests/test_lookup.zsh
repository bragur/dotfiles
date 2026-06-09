#!/usr/bin/env zsh
# tests/test_lookup.zsh — Tier 1 unit tests for _zah_lookup and _zah_command_word
#
# No TTY required. Run from ~/dotfiles:
#   zsh zsh-abbr-hint/tests/test_lookup.zsh
#
# Exit code: 0 if all assertions pass, non-zero on any FAIL.

emulate -LR zsh

# ---------------------------------------------------------------------------
# Resolve paths relative to this script
# ---------------------------------------------------------------------------
_zah_test_dir="${0:a:h}"
_zah_plugin="${_zah_test_dir:h}/.config/zsh/zsh-abbr-hint.plugin.zsh"

source "${_zah_test_dir}/lib.zsh"
source "$_zah_plugin"

# ---------------------------------------------------------------------------
# Seed fixtures with (qqq)-quoted keys, matching zsh-abbr's storage format.
# The SESSION arrays are intentionally left unset to exercise the unset-array
# guard path in _zah_lookup.
# ---------------------------------------------------------------------------
typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS
k="gst";         v="git status";                ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}
k="gco";         v="git checkout";              ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}
k="dotfiles pl"; v="cd ~/dotfiles && git pull"; ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}

typeset -gA ABBR_GLOBAL_USER_ABBREVIATIONS
k="G"; v="| grep"; ABBR_GLOBAL_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}

# ABBR_REGULAR_SESSION_ABBREVIATIONS and ABBR_GLOBAL_SESSION_ABBREVIATIONS
# are intentionally NOT set — exercises the "unset/empty array" guard path.

# ---------------------------------------------------------------------------
# Lookup assertions
# ---------------------------------------------------------------------------

# Known regular key: gst — should return 0, REPLY="git status", REPLY2="regular"
_zah_lookup "gst"; _rc=$?
zah_assert_eq "lookup(gst) returns 0"   "0"          "$_rc"
zah_assert_eq "lookup(gst) REPLY"       "git status" "$REPLY"
zah_assert_eq "lookup(gst) REPLY2"      "regular"    "$REPLY2"

# Known global key: G — should return 0, REPLY2="global"
_zah_lookup "G"; _rc=$?
zah_assert_eq "lookup(G) returns 0"     "0"      "$_rc"
zah_assert_eq "lookup(G) REPLY2"        "global" "$REPLY2"

# Unknown key: gsx — should return 1
_zah_lookup "gsx"; _rc=$?
zah_assert_eq "lookup(gsx) returns 1"   "1"      "$_rc"

# Space-containing key: "dotfiles pl" — proves (qqq) probe matches a quoted key
_zah_lookup "dotfiles pl"; _rc=$?
zah_assert_eq "lookup('dotfiles pl') returns 0"  "0"                           "$_rc"
zah_assert_eq "lookup('dotfiles pl') REPLY"      "cd ~/dotfiles && git pull"   "$REPLY"
zah_assert_eq "lookup('dotfiles pl') REPLY2"     "regular"                     "$REPLY2"

# Unset session arrays — must not error and must return 1
_zah_lookup "anything_not_set"; _rc=$?
zah_assert_eq "lookup with unset session arrays returns 1"  "1"  "$_rc"

# ---------------------------------------------------------------------------
# Tokenizer (_zah_command_word) assertions
# ---------------------------------------------------------------------------

# gst alone at line start = command position
BUFFER="gst"; CURSOR=3
_zah_command_word
zah_assert_eq "tokenizer: gst at start — REPLY"   "gst" "$REPLY"
zah_assert_eq "tokenizer: gst at start — REPLY2"  "1"   "$REPLY2"

# echo gst — gst is an argument, not command position
BUFFER="echo gst"; CURSOR=8
_zah_command_word
zah_assert_eq "tokenizer: echo gst — REPLY"   "gst" "$REPLY"
zah_assert_eq "tokenizer: echo gst — REPLY2"  "0"   "$REPLY2"

# ls ; gst — first word after ';' is command position
BUFFER="ls ; gst"; CURSOR=8
_zah_command_word
zah_assert_eq "tokenizer: after ';' — REPLY2"  "1" "$REPLY2"

# foo | gst — first word after '|' is command position
BUFFER="foo | gst"; CURSOR=9
_zah_command_word
zah_assert_eq "tokenizer: after '|' — REPLY2"  "1" "$REPLY2"

# ---------------------------------------------------------------------------
# Finish — non-zero exit on any failure
# ---------------------------------------------------------------------------
zah_finish; exit $?
