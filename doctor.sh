#!/usr/bin/env bash
#
# doctor.sh — read-only health check for this dotfiles setup.
#
# Prints ✓/✗ per check and exits non-zero if any required check fails.
# Warn-only checks (marked "warn") never affect the exit code.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILURES=0

pass() { printf '\033[32m✓\033[0m %s\n' "$*"; }
failed() { printf '\033[31m✗\033[0m %s\n' "$*"; FAILURES=$((FAILURES + 1)); }
warn() { printf '\033[33m✗ (warn)\033[0m %s\n' "$*"; }

# --- Required commands --------------------------------------------------------
echo "== Commands =="
for cmd in nix darwin-rebuild stow git mise node atuin zoxide fzf oh-my-posh tmux nvim gh; do
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "command: $cmd"
  else
    failed "command: $cmd not found"
  fi
done

# --- Stow symlinks ------------------------------------------------------------
# Each key path must be a symlink that resolves to a path inside the repo.
echo
echo "== Stowed symlinks =="
check_link() {
  local path="$1" resolved
  if [ ! -L "$path" ]; then
    failed "symlink: $path is not a symlink"
    return
  fi
  resolved="$(cd "$(dirname "$path")" 2>/dev/null && cd "$(dirname "$(readlink "$path")")" 2>/dev/null && pwd)/$(basename "$(readlink "$path")")"
  case "$resolved" in
    "$DOTFILES_DIR"/*) pass "symlink: $path -> repo" ;;
    *) failed "symlink: $path resolves outside repo ($resolved)" ;;
  esac
}

check_link "$HOME/.zshrc"
check_link "$HOME/.zsh_plugins.txt"
check_link "$HOME/.tmux.conf"
check_link "$HOME/.gitconfig"
check_link "$HOME/.config/ghostty"
check_link "$HOME/.config/nvim"
check_link "$HOME/.config/karabiner"
check_link "$HOME/.config/mise"
check_link "$HOME/.config/atuin"
check_link "$HOME/.config/zsh-abbr"
check_link "$HOME/.config/oh-my-posh"
check_link "$HOME/.claude/statusline-with-usage.sh"
# ~/.config/zsh is a real directory shared by two stow packages (zsh and
# zsh-abbr-hint) — its tracked files are per-file symlinks.
for f in aliases.zsh antidote.zsh exports.zsh functions.zsh options.zsh zsh-abbr-hint.plugin.zsh; do
  check_link "$HOME/.config/zsh/$f"
done

# --- Shell health -------------------------------------------------------------
echo
echo "== Shell =="
if zsh -ic 'exit 0' >/dev/null 2>&1; then
  pass "zsh starts clean (zsh -ic 'exit 0')"
else
  failed "zsh does not start clean"
fi

# zsh-abbr loads via zsh-defer, which only fires when zle idles at a prompt.
# Drive a real interactive shell through a pty and give it an idle window.
abbr_type="$({ sleep 2; printf 'type -w abbr\n'; sleep 1; printf 'exit\n'; } \
  | script -q /dev/null zsh -i 2>/dev/null | grep -c 'abbr: function' || true)"
if [ "${abbr_type:-0}" -ge 1 ]; then
  pass "abbr is a defined function in an interactive shell"
else
  failed "abbr did not load in an interactive shell"
fi

# --- Tool plumbing ------------------------------------------------------------
echo
echo "== Tools =="
if [ -f /run/current-system/sw/share/antidote/antidote.zsh ] \
  || [ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ] \
  || [ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]; then
  pass "antidote reachable"
else
  failed "antidote not found (nix pathsToLink or homebrew)"
fi

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  pass "TPM installed"
else
  warn "TPM not installed yet — start tmux once, then prefix+I (fine pre-first-tmux)"
fi

if [ -f "$HOME/.config/oh-my-posh/config.toml" ]; then
  pass "oh-my-posh config present"
else
  failed "oh-my-posh config missing (~/.config/oh-my-posh/config.toml)"
fi

# --- Result -------------------------------------------------------------------
echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
