# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for macOS (Apple Silicon) using a hybrid management approach:
- **nix-darwin**: Declarative system configuration (packages, Homebrew, macOS settings)
- **stow**: Dotfile symlink management (each root directory is a stow package)
- **mise**: Development tool version management (Node.js, Python, etc.)

## Key Commands

### System Updates
```bash
# Update and rebuild system (packages, Homebrew, settings)
cd ~/dotfiles/nix/nix && nix flake update && sudo darwin-rebuild switch --flake '.#air'

# Dry run to see what will change
sudo darwin-rebuild build --flake ~/dotfiles/nix/nix/.#air

# Rollback to previous generation
sudo darwin-rebuild --rollback

# Validate nix flake
cd ~/dotfiles/nix/nix && nix flake check
```

### Stow Operations
```bash
# Symlink a config package (from ~/dotfiles)
stow zsh          # zsh/.zshrc -> ~/.zshrc
stow nvim          # nvim/.config/nvim -> ~/.config/nvim

# Remove symlinks
stow -D zsh
```

### Development Tools
```bash
mise list         # See installed tools
mise upgrade      # Update all tools
mise use -g node@22  # Set global version
```

## Architecture

### Directory Structure
Each root-level directory is a **stow package** that mirrors home directory structure:
- `zsh/` - Shell config (`.zshrc` sources modular configs from `.config/zsh/`)
- `nvim/` - Neovim (LazyVim-based, in `.config/nvim/`)
- `tmux/` - Multiplexer config and scripts
- `nix/nix/` - nix-darwin flake (not a stow package)
- `zsh-abbr/` - 223+ command abbreviations
- `oh-my-posh/`, `ghostty/`, `mise/`, `atuin/` - Tool configs

### Configuration Flow
1. **Shell init**: `.zshrc` → sources `.config/zsh/{exports,aliases,functions,options}.zsh`
2. **Plugins**: Antidote loads from `.zsh_plugins.txt`
3. **Prompt**: oh-my-posh with Catppuccin theme
4. **Tools**: mise activates, zoxide/fzf/carapace integrate

### Neovim
- Location: `nvim/.config/nvim/`
- Framework: LazyVim with custom plugins in `lua/plugins/`
- Keymaps: Icelandic keyboard layout (Option key bindings differ)
- Integration: Seamless navigation with tmux panes via `Ctrl+hjkl`

### Nix-Darwin
- Flake location: `nix/nix/flake.nix`
- Machine configs: `air` (MacBook Air), `main` (MacBook Pro) — both aarch64-darwin
- **Package split**: CLI tools via nix (`environment.systemPackages`), GUI apps with auto-updaters via Homebrew casks
- Homebrew: Managed with `onActivation.cleanup = "zap"` - manual `brew install` is temporary
- Keep entries in `systemPackages`, `casks`, `brews`, and `taps` alphabetically sorted

## Gotchas

### Nix-darwin pathsToLink
- Packages that only install to `/share` (e.g. zsh plugins like antidote) won't appear in the system profile unless their path is added to `environment.pathsToLink` (e.g. `[ "/share/antidote" ]`)
- After adding a nix package, verify it's accessible: check `/run/current-system/sw/bin/<name>` or `/run/current-system/sw/share/<name>`

### Fresh install / machine migration
- Migration Assistant does NOT migrate nix — it must be reinstalled from scratch
- Use the **Determinate Systems installer** (not the official nixos.org one):
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```
  The official installer has macOS issues: no flakes by default, wrong SSL cert path (`/etc/ssl/certs/ca-certificates.crt` instead of macOS `/etc/ssl/cert.pem`), flaky daemon startup
- After install, restart terminal and bootstrap nix-darwin:
  ```bash
  cd ~/dotfiles/nix/nix && nix run nix-darwin -- switch --flake '.#<hostname>'
  ```
  (`darwin-rebuild` is not available until after first nix-darwin build)
- The `ls` alias (`eza`) won't work until nix packages are installed — use `/bin/ls` during bootstrap

### Shell config verification
- After any shell config change, verify in a fresh shell (`exec zsh` or new terminal) — not the current session
- For plugin managers, verify the plugin command loads: `type abbr`, `type atuin`, `antidote --version`

## Agents

Agents are in `.claude/agents/`:
- `dotfiles-specialist` - Tmux, neovim, shell config, and dotfiles tasks
- `nix-reviewer` - Reviews flake.nix changes for pitfalls before rebuilding

## Skills

- `/nix-rebuild` - Validate, dry-run preview, and rebuild nix-darwin with rollback support
- `/add-package` - Add packages to nix (CLI) or Homebrew casks (GUI) with rebuild

## Hooks

Configured in `.claude/settings.json`:
- **PreToolUse**: Blocks edits to `flake.lock` and `.zcompdump` (generated files)
- **PostToolUse**: Auto-runs `nix flake check` after editing `flake.nix`

## Important Notes

- Theme: Catppuccin Mocha across all tools
- Font: Maple Mono NF (Nerd Font)
- Homebrew apps installed manually will be removed on next `darwin-rebuild`
- To add permanent packages, edit `nix/nix/flake.nix`
