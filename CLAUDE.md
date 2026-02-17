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
stow nvim-distros # nvim-distros/.config/nvim-distros -> ~/.config/nvim-distros

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
- `nvim-distros/` - Neovim (LazyVim-based, in `.config/nvim-distros/lazyvim/`)
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
- Location: `nvim-distros/.config/nvim-distros/lazyvim/`
- Framework: LazyVim with custom plugins in `lua/plugins/`
- Keymaps: Icelandic keyboard layout (Option key bindings differ)
- Integration: Seamless navigation with tmux panes via `Ctrl+hjkl`

### Nix-Darwin
- Flake location: `nix/nix/flake.nix`
- Machine config: `air` (MacBook Air, aarch64-darwin)
- **Package split**: CLI tools via nix (`environment.systemPackages`), GUI apps with auto-updaters via Homebrew casks
- Homebrew: Managed with `onActivation.cleanup = "zap"` - manual `brew install` is temporary

## Gotchas

### Nix-darwin pathsToLink
- Packages that only install to `/share` (e.g. zsh plugins like antidote) won't appear in the system profile unless their path is added to `environment.pathsToLink` (e.g. `[ "/share/antidote" ]`)
- After adding a nix package, verify it's accessible: check `/run/current-system/sw/bin/<name>` or `/run/current-system/sw/share/<name>`

### Shell config verification
- After any shell config change, verify in a fresh shell (`exec zsh` or new terminal) — not the current session
- For plugin managers, verify the plugin command loads: `type abbr`, `type atuin`, `antidote --version`

## Agents

A `dotfiles-specialist` agent is available in `.claude/agents/` for tasks involving tmux, neovim, shell configurations, and dotfiles management. It provides specialized expertise for configuration troubleshooting and implementation.

## Important Notes

- Theme: Catppuccin Mocha across all tools
- Font: Maple Mono NF (Nerd Font)
- Homebrew apps installed manually will be removed on next `darwin-rebuild`
- To add permanent packages, edit `nix/nix/flake.nix`
