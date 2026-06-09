# tests/lib.zsh — shared test helpers for zsh-abbr-hint tests
#
# Source this file at the top of each test_*.zsh:
#   source "${0:a:h}/lib.zsh"

# ---------------------------------------------------------------------------
# Antidote cache plugin paths
# ---------------------------------------------------------------------------
ZAH_CACHE="$HOME/Library/Caches/antidote"

ZAH_ABBR_PLUGIN="$ZAH_CACHE/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr/zsh-abbr.plugin.zsh"

ZAH_FSH_PLUGIN="$ZAH_CACHE/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

ZAH_GLOBALIAS_PLUGIN="$ZAH_CACHE/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/globalias/globalias.plugin.zsh"

# ---------------------------------------------------------------------------
# zah_skip <message>
#   Print a clear skip message and exit 0.
# ---------------------------------------------------------------------------
zah_skip() {
  print "SKIP: $1"
  exit 0
}

# ---------------------------------------------------------------------------
# zah_require_file <path>
#   Skip (exit 0) with a clear message if <path> does not exist.
# ---------------------------------------------------------------------------
zah_require_file() {
  [[ -f $1 ]] || zah_skip "missing dependency: $1"
}

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------
typeset -gi ZAH_FAILS=0

# zah_assert_eq <name> <expected> <actual>
#   Pass if <expected> == <actual> (exact string match).
zah_assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    print "PASS: $name"
  else
    print "FAIL: $name — expected [$expected] got [$actual]"
    (( ZAH_FAILS++ ))
  fi
}

# zah_assert_true <name> <cond-cmd...>
#   Pass if <cond-cmd...> exits 0.
zah_assert_true() {
  local name="$1"
  shift
  if "$@"; then
    print "PASS: $name"
  else
    print "FAIL: $name"
    (( ZAH_FAILS++ ))
  fi
}

# zah_finish
#   Returns 0 if all assertions passed, non-zero otherwise.
#   Intended for use at the end of a test file: zah_finish || exit 1
zah_finish() {
  (( ZAH_FAILS == 0 ))
}

# ---------------------------------------------------------------------------
# zah_zpty_drain <ptyname> <needle>
#   Reads from the named zpty session until <needle> appears in the accumulated
#   output or the idle-read counter exceeds the limit. No fixed sleep calls.
#   Sets REPLY to the accumulated output.
#
#   Uses an idle-counter approach: increments a counter on each failed read and
#   resets it to 0 on each successful read. Stops when idle > ZAH_ZPTY_MAXIDLE
#   (default 300) or when needle is found.
# ---------------------------------------------------------------------------
: "${ZAH_ZPTY_MAXIDLE:=300}"

zah_zpty_drain() {
  local ptyname="$1" needle="$2"
  local total="" chunk="" idle=0
  while (( idle < ZAH_ZPTY_MAXIDLE )); do
    if zpty -r "$ptyname" chunk 2>/dev/null; then
      total+="$chunk"
      idle=0
      [[ "$total" == *"$needle"* ]] && break
    else
      (( idle++ ))
    fi
  done
  REPLY="$total"
}
