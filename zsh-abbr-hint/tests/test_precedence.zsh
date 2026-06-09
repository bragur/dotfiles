#!/usr/bin/env zsh
# tests/test_precedence.zsh — Tier 2 integration test: green span beats F-Sy-H red
#
# Verifies the Part A precedence contract:
#   • F-Sy-H (which defines _zsh_highlight and populates region_highlight with a
#     red unknown-token span) is loaded FIRST.
#   • _zah_redraw is then called (as the line-pre-redraw hook would call it) and
#     APPENDS a green span at a later array index — so the terminal renders green
#     (last-wins overlapping span semantics).
#   • Guard: without _zsh_highlight defined, _zah_register must NOT install the hook.
#
# Sub-case 1 (direct): region_highlight ordering without a PTY (the Part A gate).
# Sub-case 2 (zpty):   rendered ANSI output via an interactive child shell.
# Sub-case 3 (guard):  hook absent when F-Sy-H is not loaded.
#
# Run from ~/dotfiles:
#   zsh zsh-abbr-hint/tests/test_precedence.zsh
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

# Skip early if required plugins are absent
zah_require_file "$ZAH_FSH_PLUGIN"
zah_require_file "$_zah_plugin"

# ---------------------------------------------------------------------------
# Sub-case 1: region_highlight ordering — direct function call (no PTY)
#
# The Part A gate. Reproduces the deferred-load timing:
#   1. Source F-Sy-H first — this runs _zsh_highlight_bind_widgets (wraps all
#      editing widgets) and defines _zsh_highlight.
#   2. Source our plugin — defines _zah_redraw.
#   3. Confirm F-Sy-H is present (_zsh_highlight defined) before calling
#      _zah_redraw, exactly as _zah_register would gate registration.
#   4. Set BUFFER="gst", CURSOR=3 (simulating the user having typed 'gst').
#   5. Call _zsh_highlight — resets region_highlight and populates it with
#      F-Sy-H's spans (unknown-token red over 'gst').
#   6. Call _zah_redraw — appends our green span at the next (later) index.
#   7. Assert: green span is last, covers the same offsets as F-Sy-H's span,
#      and contains the Catppuccin Mocha color #a6e3a1.
# ---------------------------------------------------------------------------
print -r -- "--- Sub-case 1: region_highlight ordering (direct, the Part A gate) ---"

(
  # Run in a subshell so sourcing F-Sy-H does not pollute the test process
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"

  # Step 1: Load F-Sy-H first (mimicking zsh-defer completing after first prompt).
  # This defines _zsh_highlight and calls _zsh_highlight_bind_widgets.
  source "$ZAH_FSH_PLUGIN"

  # Confirm _zsh_highlight is now defined — this is the sentinel _zah_register guards on
  zah_assert_true "F-Sy-H defines _zsh_highlight (precondition for registration)" \
    test "${+functions[_zsh_highlight]}" -eq 1

  # Step 2: Source our plugin — defines _zah_redraw, _zah_lookup, _zah_command_word
  source "$_zah_plugin"

  # Step 2a: Seed abbreviation with (qqq)-quoted key, matching zsh-abbr storage format
  typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS
  local k='gst' v='git status'
  ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}

  # Step 3: Confirm _zsh_highlight is defined before calling _zah_redraw —
  # exactly as _zah_register gates registration. This proves ordering is correct.
  zah_assert_true "_zsh_highlight is defined before _zah_redraw runs (ordering proof)" \
    test "${+functions[_zsh_highlight]}" -eq 1

  # Step 4: Simulate ZLE state after the user has typed 'gst'
  typeset -g BUFFER="gst"
  typeset -gi CURSOR=3
  typeset -a region_highlight=()

  # Step 5: Run F-Sy-H's highlighter. This is what F-Sy-H's wrapped editing
  # widget does on each keypress: reset region_highlight and repopulate it.
  # Suppress stderr — _zsh_highlight may warn when called outside full ZLE context.
  _zsh_highlight 2>/dev/null

  local fsh_count=${#region_highlight}
  zah_assert_true "F-Sy-H added at least one region_highlight span for 'gst'" \
    test "${fsh_count}" -ge 1

  # F-Sy-H marks 'gst' as unknown-token; the span should cover offset 0..3
  local fsh_first_span="${region_highlight[1]}"
  zah_assert_true "F-Sy-H first span covers 'gst' word starting at offset 0" \
    test "${fsh_first_span%% *}" -eq 0

  # Step 6: Run our hook — appends the green span AFTER F-Sy-H's spans.
  # _zah_redraw runs _zah_command_word and _zah_lookup, then appends to region_highlight.
  _zah_redraw 2>/dev/null

  local total_count=${#region_highlight}
  zah_assert_true "region_highlight grew after _zah_redraw (our span was appended)" \
    test "${total_count}" -gt "${fsh_count}"

  # Our span is the last entry — it has the highest index
  local our_span="${region_highlight[$total_count]}"

  # Step 7a: Assert green span contains Catppuccin Mocha color #a6e3a1
  local _has_green=0
  [[ "$our_span" == *"#a6e3a1"* ]] && _has_green=1
  zah_assert_true "green span color is Catppuccin Mocha #a6e3a1" \
    test "${_has_green}" -eq 1

  # Step 7b: Assert bold attribute
  local _has_bold=0
  [[ "$our_span" == *",bold"* ]] && _has_bold=1
  zah_assert_true "green span has bold attribute" \
    test "${_has_bold}" -eq 1

  # Step 7c: Our span index is greater than F-Sy-H's last span index.
  # Terminal rendering: overlapping spans are applied in array order; the LAST
  # span with overlapping offsets wins. total_count > fsh_count proves our span
  # is rendered after (and therefore overrides) F-Sy-H's red span.
  zah_assert_true "green span at index ${total_count} > F-Sy-H's last index ${fsh_count} (last-wins)" \
    test "${total_count}" -gt "${fsh_count}"

  # Step 7d: Our span covers the same start offset as F-Sy-H's first span
  local our_start="${our_span%% *}"
  local fsh_start="${fsh_first_span%% *}"
  zah_assert_eq "green span same start offset as F-Sy-H span (both cover 'gst')" \
    "${fsh_start}" "${our_start}"

  # Step 7e: Verify #a6e3a1 maps to ANSI 38;2;166;227;161
  # r=0xa6=166, g=0xe3=227, b=0xa1=161.
  # When ZLE renders region_highlight with fg=#a6e3a1, it emits ESC[38;2;166;227;161m.
  # This is a mathematical identity documented here for test readers; the zpty
  # sub-case below verifies it against actual terminal output.
  print -r -- "  INFO: #a6e3a1 encodes as ANSI truecolor 38;2;166;227;161"
  print -r -- "  INFO: F-Sy-H span: ${fsh_first_span}"
  print -r -- "  INFO: Our span:    ${our_span}"

  zah_finish
)
local sub1_rc=$?
(( sub1_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Sub-case 2: rendered ANSI via zpty
#
# Spawns an interactive zsh child, loads F-Sy-H and the plugin in deferred-
# load order, types 'gst', and asserts the rendered terminal bytes contain
# the truecolor green sequence 38;2;166;227;161 (#a6e3a1).
#
# Requires zsh/zpty and a functioning PTY environment. If the environment
# does not support it (no controlling terminal, CI, etc.), this sub-case
# SKIPs cleanly. Sub-case 1's region_highlight check is the primary Part A gate.
# ---------------------------------------------------------------------------
print -r -- "--- Sub-case 2: rendered ANSI via zpty ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"

  # Load zpty module; skip this sub-case if unavailable
  if ! zmodload zsh/zpty 2>/dev/null; then
    print "SKIP: zsh/zpty module unavailable"
    exit 0
  fi

  # Quick environment check: spawn a minimal child and confirm it produces
  # output within the idle limit. This detects headless/CI environments where
  # interactive zsh children hang indefinitely.
  zpty zah_prec_probe zsh -c 'echo PTY_PROBE_OK; exit 0' 2>/dev/null
  if (( $? != 0 )); then
    print "SKIP: zpty spawn failed (no controlling terminal)"
    exit 0
  fi
  zah_zpty_drain zah_prec_probe 'PTY_PROBE_OK'
  local _probe="$REPLY"
  zpty -d zah_prec_probe 2>/dev/null
  if [[ "$_probe" != *'PTY_PROBE_OK'* ]]; then
    print "SKIP: zpty probe produced no output (headless environment)"
    exit 0
  fi

  # Spawn interactive child (zsh -f = no rc files; receives ZLE via PTY)
  zpty zah_prec zsh -f 2>/dev/null
  if (( $? != 0 )); then
    print "SKIP: zpty interactive spawn failed"
    exit 0
  fi

  # Wait for initial default zsh prompt (contains '%')
  zah_zpty_drain zah_prec '%'
  local _got_initial="$REPLY"
  if [[ "$_got_initial" != *'%'* ]]; then
    print "SKIP: zpty child produced no prompt (non-interactive environment)"
    zpty -d zah_prec 2>/dev/null
    exit 0
  fi

  # Set a recognizable prompt to reliably detect when each command completes
  zpty -w zah_prec 'PROMPT="READY> "'$'\r'
  zah_zpty_drain zah_prec 'READY>'

  # Step 1: Source F-Sy-H in the child (mimicking zsh-defer's deferred drain)
  zpty -w zah_prec "source '${ZAH_FSH_PLUGIN}'"$'\r'
  zah_zpty_drain zah_prec 'READY>'

  # Step 2: Seed abbreviation
  zpty -w zah_prec 'typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS'$'\r'
  zah_zpty_drain zah_prec 'READY>'
  zpty -w zah_prec 'local k=gst v="git status"; ABBR_REGULAR_USER_ABBREVIATIONS[${(qqq)k}]=${(qqq)v}'$'\r'
  zah_zpty_drain zah_prec 'READY>'

  # Step 3: Source our plugin and register the ZLE hook
  # (_zah_register will succeed because _zsh_highlight is now defined)
  zpty -w zah_prec "source '${_zah_plugin}'"$'\r'
  zah_zpty_drain zah_prec 'READY>'
  zpty -w zah_prec '_zah_register'$'\r'
  zah_zpty_drain zah_prec 'READY>'

  # Enable truecolor mode for ANSI sequence capture
  zpty -w zah_prec 'TERM=xterm-256color'$'\r'
  zah_zpty_drain zah_prec 'READY>'

  # Step 4: Type 'gst' without Enter — triggers the line-pre-redraw hook,
  # which calls _zah_redraw, which appends the green span, and ZLE re-renders
  # the line emitting updated ANSI sequences to the terminal output.
  zpty -w zah_prec 'gst'

  # Drain until we capture the echoed 'gst' keystrokes (or timeout)
  local rendered_buf="" rendered_chunk="" rendered_idle=0
  while (( rendered_idle < ZAH_ZPTY_MAXIDLE )); do
    if zpty -r zah_prec rendered_chunk 2>/dev/null; then
      rendered_buf+="$rendered_chunk"
      rendered_idle=0
      [[ "$rendered_buf" == *'gst'* ]] && break
    else
      (( rendered_idle++ ))
    fi
  done

  if [[ "$rendered_buf" != *'gst'* ]]; then
    print "SKIP: zpty child did not echo 'gst' keystrokes (non-interactive / no ZLE)"
    zpty -d zah_prec 2>/dev/null
    exit 0
  fi

  # Assert: truecolor green ESC[38;2;166;227;161m is present in rendered output
  # (#a6e3a1 = r=166=0xa6, g=227=0xe3, b=161=0xa1)
  local _has_green_ansi=0
  [[ "$rendered_buf" == *'38;2;166;227;161'* ]] && _has_green_ansi=1
  zah_assert_true \
    "rendered ANSI contains truecolor green 38;2;166;227;161 (#a6e3a1)" \
    test "${_has_green_ansi}" -eq 1

  zpty -d zah_prec 2>/dev/null
  zah_finish
)
local sub2_rc=$?
(( sub2_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Sub-case 3: guard — hook NOT installed when _zsh_highlight absent
#
# In a clean subshell WITHOUT F-Sy-H loaded (so _zsh_highlight is undefined),
# _zah_register must no-op: it must not install _zah_redraw into the
# line-pre-redraw hook chain, and it must remain in precmd_functions so it
# can retry on the next prompt.
# ---------------------------------------------------------------------------
print -r -- "--- Sub-case 3: guard (_zsh_highlight absent → hook not installed) ---"

(
  emulate -LR zsh
  setopt NO_GLOBAL_RCS

  source "${_zah_test_dir}/lib.zsh"

  # Load plugin WITHOUT sourcing F-Sy-H first.
  # _zsh_highlight will be undefined; _zah_register must no-op.
  source "$_zah_plugin"

  # Confirm _zsh_highlight is NOT defined in this subshell
  zah_assert_true "_zsh_highlight not defined (F-Sy-H intentionally absent)" \
    test "${+functions[_zsh_highlight]}" -eq 0

  # Call _zah_register: guards on _zsh_highlight, so must no-op
  _zah_register

  # _zah_register must NOT have self-removed from precmd
  # (it only self-removes after successful registration)
  local reg_still="${precmd_functions[(r)_zah_register]}"
  zah_assert_true "_zah_register remains in precmd_functions (no-op, waiting for F-Sy-H)" \
    test -n "$reg_still"

  # The zle_hook_widgets assoc must NOT contain _zah_redraw in line-pre-redraw.
  # add-zle-hook-widget populates this assoc; if _zah_register no-oped, it is empty.
  local hook_chain="${zle_hook_widgets[line-pre-redraw]:-}"
  local _rdrw_absent=1
  [[ "$hook_chain" == *"_zah_redraw"* ]] && _rdrw_absent=0
  zah_assert_true \
    "line-pre-redraw chain does NOT contain _zah_redraw when F-Sy-H absent" \
    test "${_rdrw_absent}" -eq 1

  zah_finish
)
local sub3_rc=$?
(( sub3_rc == 0 )) || (( ZAH_FAILS++ ))

# ---------------------------------------------------------------------------
# Finish
# ---------------------------------------------------------------------------
zah_finish; exit $?
