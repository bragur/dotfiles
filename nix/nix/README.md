# Nix-Darwin Setup Guide

This directory contains the nix-darwin configuration for managing your macOS system declaratively.

## What This Setup Does

This Nix flake manages:
- **System packages** via Nix (neovim, tmux, zsh, stow, mise, etc.)
- **Homebrew integration** (manages Homebrew installation and casks)
- **macOS system settings** (Dock, Finder, keyboard repeat rate, etc.)
- **GUI applications** via Homebrew casks (Cursor, Ghostty, 1Password, etc.)

## Current Configuration

### System Packages (Nix-managed)
Located in: `flake.nix` → `environment.systemPackages`

These are installed system-wide and available in your PATH:
- **Shell tools**: zsh, oh-my-posh, fzf, zoxide, eza, bat
- **Dev tools**: neovim, tmux, tmuxifier, stow, mise, git
- **Utilities**: autojump
- **GUI apps**: obsidian, slack, vscode

### Homebrew Packages
Located in: `flake.nix` → `homebrew.brews` and `homebrew.casks`

**Brews** (CLI tools):
- antidote (zsh plugin manager)
- mas (Mac App Store CLI)

**Casks** (GUI apps):
- Cursor, Ghostty, 1Password, Hyperkey

### macOS Settings
Located in: `flake.nix` → `system.defaults`

- Dock autohides
- Finder uses column view
- Fast key repeat rate
- Persistent Dock apps configured

## How to Make Changes

### Adding a New Package

1. **Nix package** (command-line tool):
   ```nix
   environment.systemPackages = [
     pkgs.your-package-name
   ];
   ```

2. **Homebrew formula**:
   ```nix
   homebrew.brews = [
     "package-name"
   ];
   ```

3. **Homebrew cask** (GUI app):
   ```nix
   homebrew.casks = [
     "app-name"
   ];
   ```

### Updating Packages

```bash
cd ~/dotfiles/nix/nix

# Update all inputs (nixpkgs, nix-darwin, homebrew)
nix flake update

# Apply changes
sudo darwin-rebuild switch --flake '.#air'
```

### Changing System Settings

Edit the `system.defaults` section in `flake.nix`. See [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for all available settings.

### Applying Changes

After editing `flake.nix`:

```bash
cd ~/dotfiles/nix/nix
sudo darwin-rebuild switch --flake '.#air'
```

## Mise (Development Tools)

**Mise** is installed via Nix and manages your dev tool versions (Node.js, Python, Ruby, etc.).

### Current Setup

Global tools are configured in: `~/.config/mise/config.toml`

Currently installed:
- Node.js 22.20.0 (LTS) - includes npm 10.9.3
- Yarn 4.10.3

### Using Mise

```bash
# See what's installed
mise list

# Install a tool globally
mise use -g node@20.10.0
mise use -g python@3.12

# Install tools for a specific project (creates .mise.toml)
cd your-project
mise use node@18.19.0
mise use yarn@1.22.19

# Update all tools
mise upgrade
```

Mise automatically switches versions based on your directory!

## Homebrew Paths

Your system uses **two Homebrew installations**:

1. **Nix-managed Homebrew** (recommended): `/opt/homebrew`
   - Managed by nix-darwin
   - Updated when you run `darwin-rebuild`
   - Use: `/opt/homebrew/bin/brew`

2. **Legacy Homebrew**: `/usr/local` (Intel path)
   - Leftover from before Nix setup
   - Can be removed once you're comfortable with the Nix setup

To use the correct Homebrew:
```bash
/opt/homebrew/bin/brew install package-name
```

### ⚠️ Important: Homebrew Cleanup Behavior

This configuration uses `onActivation.cleanup = "zap"`, which means:

**Every time you run `darwin-rebuild switch`:**
- ✅ Packages declared in `flake.nix` → `homebrew.brews` are **kept**
- ✅ Casks declared in `flake.nix` → `homebrew.casks` are **kept**
- ❌ Any manually installed packages (`brew install something`) are **REMOVED**

This ensures your system stays clean and reproducible. If you want to keep a package permanently, add it to `flake.nix`.

## Troubleshooting

### "command not found" after rebuild

Restart your shell or source your zshrc:
```bash
exec zsh
# or
source ~/.zshrc
```

### Homebrew errors about Intel/ARM paths

Make sure you're using `/opt/homebrew/bin/brew` on Apple Silicon:
```bash
which brew  # Should show /opt/homebrew/bin/brew
```

### mise tool not found

Restart your shell to activate mise:
```bash
exec zsh
mise doctor  # Verify mise is working
```

### Rolling back changes

Nix keeps previous system generations:
```bash
# List available generations
sudo darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild --rollback
```

## Version Information

Last updated: October 8, 2025

- **macOS**: 26.0.1 (Tahoe)
- **Nix**: 2.31.2
- **nix-darwin**: 25.11
- **Homebrew**: 4.6.12
- **mise**: 2025.9.10

## Useful Commands

```bash
# Rebuild system
sudo darwin-rebuild switch --flake ~/dotfiles/nix/nix/.#air

# Update all packages
cd ~/dotfiles/nix/nix && nix flake update && sudo darwin-rebuild switch --flake '.#air'

# Check what will change (dry run)
sudo darwin-rebuild build --flake ~/dotfiles/nix/nix/.#air

# Clean up old generations (frees disk space)
sudo nix-collect-garbage -d

# See all nix-darwin options
man configuration.nix
```

## Philosophy

This setup follows a **hybrid approach**:

- **Nix-darwin**: Infrastructure as code - system packages, settings, Homebrew integration
- **Homebrew**: GUI applications and tools that need macOS-specific integration
- **mise**: Development tools (Node, Python, etc.) - flexible per-project versions
- **stow**: Dotfiles - directly editable configs (nvim, zsh, tmux, etc.)

This gives you:
- ✅ Reproducible system configuration
- ✅ Easy migration to new machines
- ✅ Quick iteration on dev tool versions
- ✅ Simple dotfile editing without rebuilds

## Migration to New Machine

1. Install Nix: `sh <(curl -L https://nixos.org/nix/install)`
2. Enable flakes: `mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`
3. Clone dotfiles: `git clone <your-repo> ~/dotfiles`
4. Apply config: `cd ~/dotfiles/nix/nix && sudo darwin-rebuild switch --flake '.#air'`
5. Restart shell: `exec zsh`
6. Install dev tools: `mise install`

Done! 🎉

