#!/usr/bin/env bash
#
# install-addons.sh — opt-in personal add-ons, kept out of ./bootstrap.sh.
#
# These configs reference hardware and app setups specific to one person
# (a Loopback device named "Æon", an iFi xDSD, AirPods), so they are not part
# of the core dotfiles every account gets.
#
# Idempotent: re-running only re-stows and re-reports.
#
# Usage: ./install-addons.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_PACKAGES=(audiohijack hammerspoon)

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*"; }
todo() { printf '\033[35m[todo]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[fail]\033[0m %s\n' "$*"; exit 1; }

command -v stow >/dev/null 2>&1 || fail "stow not found — run ./bootstrap.sh first"

# --- stow the add-on packages -------------------------------------------------
for pkg in "${ADDON_PACKAGES[@]}"; do
  stow -R -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
  ok "stowed $pkg"
done

# --- report what nix must still provide ---------------------------------------
# The hammerspoon cask lives in nix/nix/addons/audio-routing.nix, imported only
# when flake.nix's `username` matches; a rebuild is what actually installs it.
if [ -d /Applications/Hammerspoon.app ]; then
  ok "Hammerspoon installed"
else
  todo "install Hammerspoon: cd nix/nix && sudo darwin-rebuild switch --flake '.#air'"
fi

for app in "Audio Hijack" Loopback; do
  if [ -d "/Applications/$app.app" ]; then
    ok "$app installed"
  else
    warn "$app not installed — audio switching will do nothing without it"
  fi
done

# --- manual steps no script can perform ---------------------------------------
if [ "$(defaults read com.rogueamoeba.audiohijack allowExternalCommands 2>/dev/null)" = "1" ]; then
  ok "Audio Hijack external scripting enabled"
else
  todo "Audio Hijack -> Settings -> Advanced -> Scripting: check 'Allow execution of external scripts'"
fi

todo "Hammerspoon -> Preferences: check 'Launch Hammerspoon at login'"

printf '\n'
ok "add-ons stowed. Verify by selecting 'Æon' as the output device, then:"
printf "     tail -f ~/.hammerspoon/aeon.log\n"
