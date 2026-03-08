---
name: add-package
description: Add a package to nix-darwin (CLI tools via nix, GUI apps via Homebrew cask)
disable-model-invocation: true
---

# Add Package

Add a package to the nix-darwin system configuration.

## Arguments

The user should provide the package name(s) to install.

## Decision Logic

Determine the correct installation method:

- **Nix (`environment.systemPackages`)**: CLI tools, utilities, libraries, and any app without an auto-updater
- **Homebrew cask**: GUI apps with auto-updaters (e.g., browsers, editors, chat apps) — Nix's immutable store prevents in-place updates

If unsure which category a package falls into, ask the user.

## Steps

1. **Search for the package**:
   - For nix: `nix search nixpkgs#<name>` to find the correct attribute name
   - For Homebrew: `brew search <name>` to confirm it exists as a cask

2. **Edit `~/dotfiles/nix/nix/flake.nix`**:
   - For nix packages: Add `pkgs.<name>` to `environment.systemPackages` in alphabetical order
   - For Homebrew casks: Add `"<name>"` to `homebrew.casks` in alphabetical order
   - For Homebrew formulae (rare): Add to `homebrew.brews`

3. **Rebuild** using the `/nix-rebuild` skill to validate and apply the change.

4. **Verify** the package is available:
   - For nix: `which <command>` or check `/run/current-system/sw/bin/<name>`
   - For Homebrew: `which <command>` or `brew list <name>`

## Gotcha

If a nix package only installs to `/share` (like zsh plugins), it needs a corresponding entry in `environment.pathsToLink`. Check if the package provides binaries or only share files.
