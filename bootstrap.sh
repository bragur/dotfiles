#!/usr/bin/env bash
#
# bootstrap.sh — set up a fresh Mac (or a second account) from this repo.
#
# Idempotent: every step checks whether it is already done and skips if so.
# Safe on a machine where nix is already installed — the installer is NEVER
# re-run over an existing installation.
#
# Usage: ./bootstrap.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$DOTFILES_DIR/nix/nix"
STOW_PACKAGES=(atuin claude ghostty git karabiner mise nvim oh-my-posh tmux zsh zsh-abbr zsh-abbr-hint)
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$*"; }
skip() { printf '\033[36m[skip]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[fail]\033[0m %s\n' "$*"; exit 1; }

# --- Xcode Command Line Tools -------------------------------------------------
if xcode-select -p >/dev/null 2>&1; then
  skip "Xcode Command Line Tools already installed"
else
  fail "Xcode Command Line Tools missing. Run 'xcode-select --install', finish the dialog, then re-run this script."
fi

# --- Nix ----------------------------------------------------------------------
# NEVER reinstall over an existing nix — re-running the installer on an
# already-nix-managed machine breaks it badly.
if command -v nix >/dev/null 2>&1 || [ -d /nix/store ]; then
  skip "nix already present — skipping install"
else
  ok "installing nix via Determinate Systems installer"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

# Make nix available in THIS shell even right after a fresh install
if ! command -v nix >/dev/null 2>&1; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi
command -v nix >/dev/null 2>&1 || fail "nix still not on PATH — open a new terminal and re-run this script."

# --- Username guard -----------------------------------------------------------
# The flake hardcodes the macOS account name. On a machine that has never been
# nix-darwin-managed, a mismatch would bake the wrong user into the system.
flake_user="$(sed -n 's/^ *username = "\(.*\)";.*/\1/p' "$FLAKE_DIR/flake.nix" | head -1)"
if [ "$USER" != "$flake_user" ] && [ ! -d /run/current-system ]; then
  fail "You are '$USER' but the flake is configured for '$flake_user'.
       Edit the 'username = \"$flake_user\";' line in nix/nix/flake.nix first, then re-run."
fi

# --- nix-darwin system --------------------------------------------------------
# On a machine that already has a nix-darwin system (e.g. setting up a second
# account), this is skipped entirely — no sudo needed for the rest.
if [ -d /run/current-system ] || command -v darwin-rebuild >/dev/null 2>&1; then
  skip "nix-darwin system already present — skipping system bootstrap"
else
  ok "bootstrapping nix-darwin (this needs sudo and takes a while)"
  (cd "$FLAKE_DIR" && sudo nix run nix-darwin -- switch --flake '.#main')
fi

# Pick up tools (stow, mise, ...) installed by the system profile
export PATH="/run/current-system/sw/bin:$PATH"
command -v stow >/dev/null 2>&1 || fail "stow not found — did the nix-darwin bootstrap succeed?"

# --- Stow packages ------------------------------------------------------------
# Conflicting real files are moved to $BACKUP_DIR before stowing.
backup_conflicts() {
  # Parse conflicting target paths out of `stow -n` output and move them aside.
  local output="$1" rel
  echo "$output" \
    | sed -n -e 's/.*existing target is neither a symlink nor a directory: //p' \
             -e 's/.*over existing target \(.*\) since.*/\1/p' \
    | while IFS= read -r rel; do
        [ -e "$HOME/$rel" ] || continue
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$HOME/$rel" "$BACKUP_DIR/$rel"
        warn "backed up conflicting file: ~/$rel -> $BACKUP_DIR/$rel"
      done
}

for pkg in "${STOW_PACKAGES[@]}"; do
  if output="$(stow -n -R -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1)"; then
    stow -R -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
    ok "stowed $pkg"
  else
    backup_conflicts "$output"
    stow -R -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
    ok "stowed $pkg (conflicts backed up to $BACKUP_DIR)"
  fi
done

# --- mise (dev tool versions: node, python, ...) ------------------------------
if command -v mise >/dev/null 2>&1; then
  ok "running mise install"
  mise install
else
  warn "mise not on PATH — run 'mise install' after restarting your shell"
fi

# --- Done ---------------------------------------------------------------------
cat <<'EOF'

Bootstrap complete. Manual follow-ups:

  1. atuin login && atuin sync     # shell history sync
  2. gh auth login                 # GitHub CLI
  3. tmux                          # TPM auto-installs; then prefix+I to install plugins
  4. exec zsh                      # reload shell with everything in place
  5. ./doctor.sh                   # verify the setup

EOF
