#!/usr/bin/env zsh
# tests/test_hint.zsh — Tier 3 integration test: RPROMPT hint set/restore + globalias
#
# Verifies Part B of zsh-abbr-hint:
#   • Typing a known abbreviation sets RPROMPT to the dim "→ expansion" hint.
#   • Clearing the buffer restores the fixture RPROMPT.
#   • zle reset-prompt is NOT called when the hint string is unchanged (no thrash).
#   • Globalias case: pressing space expands a global abbreviation → hint clears,
#     no stale green span remains in region_highlight.
#
# Run from ~/dotfiles:
#   zsh zsh-abbr-hint/tests/test_hint.zsh
#
# Exit code: 0 on all PASS (or SKIP), non-zero on any FAIL.

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
# Direct-call sub-tests (no PTY required)
#
# Loads the plugin in a subshell, stubs zle() so reset-prompt calls are counted
# rather than executed (avoids "not a ZLE command" errors outside ZLE context),
# seeds abbreviation fixtures, and calls _zah_redraw directly.
# ---------------------------------------------------------------------------
print -r -- "--- Direct-call: RPROMPT hint activation, unchanged-hint gate, deactivation ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"
  source "$_zah_plugin"

  # --- Fixtures ---
  local fixture_rprompt='%F{cyan}node%f'
  RPROMPT="$fixture_rprompt"

  # Seed regular abbreviation with (qqq)-quoted keys (matching zsh-abbr storage).
  typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS
  local k='gst' v='git status'
  ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}

  # Seed global abbreviation.
  typeset -gA ABBR_GLOBAL_USER_ABBREVIATIONS
  local kg='G' vg='| grep'
  ABBR_GLOBAL_USER_ABBREVIATIONS[${(qqq)kg}]=${(qqq)vg}

  # Stub zle() — counts reset-prompt calls, no-ops everything else.
  # _ZAH_ZLE_RESET_COUNT is the counter we inspect in assertions.
  typeset -gi _ZAH_ZLE_RESET_COUNT=0
  zle() {
    if [[ "${1:-}" == "reset-prompt" ]]; then
      (( _ZAH_ZLE_RESET_COUNT++ ))
    fi
  }

  # --- Part 1: activation ---
  # Set BUFFER to a known regular abbreviation in command position.
  BUFFER='gst'
  CURSOR=3
  typeset -a region_highlight=()

  _zah_redraw 2>/dev/null

  zah_assert_eq "activation: RPROMPT set to hint" \
    "%F{#6c7086}→ git status%f" "$RPROMPT"
  zah_assert_eq "activation: _ZAH_HINT_ACTIVE is 1" \
    "1" "$_ZAH_HINT_ACTIVE"
  zah_assert_eq "activation: _ZAH_LAST_HINT set" \
    "→ git status" "$_ZAH_LAST_HINT"
  zah_assert_eq "activation: _ZAH_RPROMPT_SAVED captured fixture" \
    "$fixture_rprompt" "$_ZAH_RPROMPT_SAVED"
  zah_assert_true "activation: reset-prompt called once" \
    test "$_ZAH_ZLE_RESET_COUNT" -eq 1

  # --- Part 2: unchanged-hint gate ---
  # Call _zah_redraw again with the same BUFFER — hint must not change,
  # so reset-prompt must NOT be called again (stays at count 1).
  local count_before=$_ZAH_ZLE_RESET_COUNT
  _zah_redraw 2>/dev/null
  zah_assert_eq "unchanged-hint gate: reset-prompt NOT called again" \
    "$count_before" "$_ZAH_ZLE_RESET_COUNT"

  # --- Part 3: deactivation (buffer cleared) ---
  BUFFER=''
  CURSOR=0
  _zah_redraw 2>/dev/null

  zah_assert_eq "deactivation: RPROMPT restored to fixture" \
    "$fixture_rprompt" "$RPROMPT"
  zah_assert_eq "deactivation: _ZAH_HINT_ACTIVE is 0" \
    "0" "$_ZAH_HINT_ACTIVE"
  zah_assert_eq "deactivation: _ZAH_LAST_HINT cleared" \
    "" "$_ZAH_LAST_HINT"
  zah_assert_true "deactivation: reset-prompt called for deactivation" \
    test "$_ZAH_ZLE_RESET_COUNT" -gt "$count_before"

  # --- Part 4: _zah_restore_rprompt (zle-line-finish) ---
  # Re-activate the hint first.
  RPROMPT="$fixture_rprompt"
  BUFFER='gst'; CURSOR=3
  _ZAH_HINT_ACTIVE=0; _ZAH_LAST_HINT=""; _ZAH_RPROMPT_SAVED=""
  _zah_redraw 2>/dev/null
  zah_assert_eq "restore setup: hint is active" "1" "$_ZAH_HINT_ACTIVE"

  # Now simulate zle-line-finish: call _zah_restore_rprompt.
  _zah_restore_rprompt
  zah_assert_eq "restore: RPROMPT restored to fixture" \
    "$fixture_rprompt" "$RPROMPT"
  zah_assert_eq "restore: _ZAH_HINT_ACTIVE is 0" \
    "0" "$_ZAH_HINT_ACTIVE"
  zah_assert_eq "restore: _ZAH_LAST_HINT cleared" \
    "" "$_ZAH_LAST_HINT"

  # _zah_restore_rprompt must be a no-op when hint is not active.
  local rp_before="$RPROMPT"
  _zah_restore_rprompt
  zah_assert_eq "restore no-op: RPROMPT unchanged when hint not active" \
    "$rp_before" "$RPROMPT"

  zah_finish
)
local direct_rc=$?
(( direct_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Globalias sub-test (zpty)
#
# With F-Sy-H and globalias loaded inside a zpty child, type a global
# abbreviation ("G"), confirm the hint appears and the green span is present,
# then send a space (globalias expands → buffer changes → line-pre-redraw
# re-fires → our hook sees the expanded buffer → hint clears).
#
# Asserts after space:
#   (a) _ZAH_HINT_ACTIVE == 0 (hint cleared)
#   (b) RPROMPT restored to the fixture value
#   (c) no fg=#a6e3a1,bold span remains in region_highlight over the expanded text
#
# Skips cleanly if the antidote cache files are absent or zpty is unavailable.
# ---------------------------------------------------------------------------
print -r -- "--- Globalias case (zpty): hint clears + no stale green after expansion ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"

  # Require both F-Sy-H and globalias from the antidote cache; skip if absent.
  zah_require_file "$ZAH_FSH_PLUGIN"
  zah_require_file "$ZAH_GLOBALIAS_PLUGIN"

  # Load zpty module; skip if unavailable.
  if ! zmodload zsh/zpty 2>/dev/null; then
    print "SKIP: zsh/zpty module unavailable"
    exit 0
  fi

  # Probe PTY environment (headless/CI check).
  zpty zah_hint_probe zsh -c 'echo PTY_PROBE_OK; exit 0' 2>/dev/null
  if (( $? != 0 )); then
    print "SKIP: zpty spawn failed (no controlling terminal)"
    exit 0
  fi
  zah_zpty_drain zah_hint_probe 'PTY_PROBE_OK'
  local _probe="$REPLY"
  zpty -d zah_hint_probe 2>/dev/null
  if [[ "$_probe" != *'PTY_PROBE_OK'* ]]; then
    print "SKIP: zpty probe produced no output (headless environment)"
    exit 0
  fi

  # Spawn interactive child (no rc files, ZLE via PTY).
  zpty zah_hint zsh -f 2>/dev/null
  if (( $? != 0 )); then
    print "SKIP: zpty interactive spawn failed"
    exit 0
  fi

  # Wait for initial prompt.
  zah_zpty_drain zah_hint '%'
  if [[ "$REPLY" != *'%'* ]]; then
    print "SKIP: zpty child produced no prompt (non-interactive environment)"
    zpty -d zah_hint 2>/dev/null
    exit 0
  fi

  # Set a recognizable READY prompt.
  zpty -w zah_hint 'PROMPT="READY> "'$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 1: Set fixture RPROMPT in the child.
  zpty -w zah_hint 'RPROMPT="%F{cyan}node%f"'$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 2: Source F-Sy-H (deferred-load timing mimic).
  zpty -w zah_hint "source '${ZAH_FSH_PLUGIN}'"$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 3: Seed global abbreviation with (qqq)-quoted keys.
  zpty -w zah_hint 'typeset -gA ABBR_GLOBAL_USER_ABBREVIATIONS'$'\r'
  zah_zpty_drain zah_hint 'READY>'
  zpty -w zah_hint 'local kg=G vg="| grep"; ABBR_GLOBAL_USER_ABBREVIATIONS[${(qqq)kg}]=${(qqq)vg}'$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 4: Source our plugin and register the ZLE hooks.
  zpty -w zah_hint "source '${_zah_plugin}'"$'\r'
  zah_zpty_drain zah_hint 'READY>'
  zpty -w zah_hint '_zah_register'$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 5: Source globalias (binds space to the globalias widget).
  zpty -w zah_hint "source '${ZAH_GLOBALIAS_PLUGIN}'"$'\r'
  zah_zpty_drain zah_hint 'READY>'

  # Step 6: Type the global abbreviation "G" (without Enter).
  # This triggers line-pre-redraw → _zah_redraw → hint shown + green span.
  zpty -w zah_hint 'G'
  zah_zpty_drain zah_hint 'G'

  # Assert: RPROMPT now contains the hint (read the variable in the child).
  zpty -w zah_hint $'\r'
  zah_zpty_drain zah_hint 'READY>'
  zpty -w zah_hint 'echo "ZAH_RPROMPT_AFTER_G:${RPROMPT}:END"'$'\r'
  zah_zpty_drain zah_hint ':END'
  local _rprompt_after_g="$REPLY"

  local _has_hint=0
  [[ "$_rprompt_after_g" == *'→ | grep'* ]] && _has_hint=1
  zah_assert_true "globalias: hint shown after typing 'G'" \
    test "$_has_hint" -eq 1

  # Step 7: Now type "G" again (starting a new line) and send space to trigger
  # globalias expansion, then read the resulting state.
  zpty -w zah_hint 'G'
  zah_zpty_drain zah_hint 'G'

  # Send space — globalias widget runs: zle _expand_alias; zle expand-word; zle self-insert
  # This mutates BUFFER, triggering line-pre-redraw again. _zah_redraw sees the
  # expanded text (no longer a known abbreviation key) → hint deactivated.
  zpty -w zah_hint ' '
  zah_zpty_drain zah_hint ' '

  # Accept the line to get back to a prompt, then inspect state.
  zpty -w zah_hint $'\r'
  zah_zpty_drain zah_hint 'READY>'

  # (a) Check _ZAH_HINT_ACTIVE == 0 after expansion.
  zpty -w zah_hint 'echo "ZAH_HINT_ACTIVE:${_ZAH_HINT_ACTIVE}:END"'$'\r'
  zah_zpty_drain zah_hint ':END'
  local _hint_active_out="$REPLY"
  local _hint_inactive=0
  [[ "$_hint_active_out" == *'ZAH_HINT_ACTIVE:0:'* ]] && _hint_inactive=1
  zah_assert_true "globalias: _ZAH_HINT_ACTIVE is 0 after space-expansion" \
    test "$_hint_inactive" -eq 1

  # (b) Check RPROMPT restored (no longer shows the hint "→ | grep").
  zpty -w zah_hint 'echo "ZAH_RPROMPT_AFTER_SPACE:${RPROMPT}:END"'$'\r'
  zah_zpty_drain zah_hint ':END'
  local _rprompt_after_space="$REPLY"
  local _hint_gone=0
  [[ "$_rprompt_after_space" != *'→ | grep'* ]] && _hint_gone=1
  zah_assert_true "globalias: RPROMPT no longer contains hint after expansion" \
    test "$_hint_gone" -eq 1

  # (c) Check no stale fg=#a6e3a1,bold span in region_highlight after expansion.
  # We type "G" again and space again to get a fresh expansion, then inspect
  # region_highlight before accepting.
  zpty -w zah_hint 'G'
  zah_zpty_drain zah_hint 'G'
  zpty -w zah_hint ' '
  # Drain briefly before reading region_highlight
  zah_zpty_drain zah_hint ' '
  zpty -w zah_hint $'\r'
  zah_zpty_drain zah_hint 'READY>'
  zpty -w zah_hint 'echo "ZAH_RH:${region_highlight[*]}:END"'$'\r'
  zah_zpty_drain zah_hint ':END'
  local _rh_out="$REPLY"
  local _no_stale_green=1
  [[ "$_rh_out" == *'fg=#a6e3a1,bold'* ]] && _no_stale_green=0
  zah_assert_true "globalias: no stale fg=#a6e3a1,bold span after expansion" \
    test "$_no_stale_green" -eq 1

  zpty -d zah_hint 2>/dev/null
  zah_finish
)
local globalias_rc=$?
(( globalias_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Finish
# ---------------------------------------------------------------------------
zah_finish; exit $?
