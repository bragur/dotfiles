# Nix-Darwin Setup Guide

This directory contains the nix-darwin configuration for managing your macOS system declaratively.

## What This Setup Does

This Nix flake manages:
- **System packages** via Nix (neovim, tmux, zsh, stow, mise, etc.)
- **Homebrew integration** (manages Homebrew installation and casks)
- **macOS system settings** (Dock, Finder, keyboard repeat rate, etc.)
- **GUI applications** via Homebrew casks (Cursor, Ghostty, 1Password, etc.)

## Current Configuration

### Flake Configs

Two machine configurations share the same module:
- `#air` — MacBook Air
- `#main` — Mac Mini M4 Pro

### System Packages (Nix-managed)
Located in: `flake.nix` → `environment.systemPackages`

These are installed system-wide and available in your PATH:
- **Shell**: zsh, oh-my-posh, antidote, carapace, atuin
- **File tools**: fzf, zoxide, eza, bat, fd, ripgrep
- **Dev tools**: neovim, tmux, tmuxifier, stow, mise, gh
- **Data tools**: jq, jqp, yq, typst
- **System**: mkalias, nixfmt-rfc-style, mas, rsync, sesh, gum, cmatrix

### Homebrew Packages
Located in: `flake.nix` → `homebrew.casks`

**Brews**: (none — CLI tools are all via Nix)

**Casks** (GUI apps):
- Arc, Cursor, Ghostty, Google Chrome, 1Password
- Hyperkey, Obsidian, Raycast, Slack, Tailscale, VS Code

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
sudo darwin-rebuild switch --flake '.#air'   # or '.#main'
```

### Changing System Settings

Edit the `system.defaults` section in `flake.nix`. See [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for all available settings.

### Applying Changes

After editing `flake.nix`:

```bash
cd ~/dotfiles/nix/nix
sudo darwin-rebuild switch --flake '.#air'   # or '.#main'
```

## Mise (Development Tools)

**Mise** is installed via Nix and manages your dev tool versions (Node.js, Python, Ruby, etc.).

### Current Setup

Global tools are configured in: `~/.config/mise/config.toml`

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

## Homebrew

Homebrew is installed and managed by nix-darwin at `/opt/homebrew`.

### Cleanup Behavior

This configuration uses `onActivation.cleanup = "zap"`, which means:

**Every time you run `darwin-rebuild switch`:**
- Packages declared in `flake.nix` → `homebrew.brews` are **kept**
- Casks declared in `flake.nix` → `homebrew.casks` are **kept**
- Any manually installed packages (`brew install something`) are **REMOVED**

This ensures your system stays clean and reproducible. If you want to keep a package permanently, add it to `flake.nix`.

## Spotlight and GUI Applications

### Nix-Installed Apps

GUI applications installed via Nix appear in:
- **Location**: `/Applications/Nix Apps/`
- **Spotlight label**: Shows as "alias" (this is expected and correct)

The apps are created using **mkalias**, which generates native macOS aliases (not symlinks). This ensures:
- Spotlight indexing works
- Dock pinning works
- LaunchServices file associations work

### Homebrew Cask Apps

Apps installed via Homebrew casks install directly to:
- **Location**: `/Applications/`
- **Spotlight label**: Shows as regular applications

## Troubleshooting

### "command not found" after rebuild

Restart your shell or source your zshrc:
```bash
exec zsh
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

## Useful Commands

```bash
# Rebuild system
sudo darwin-rebuild switch --flake ~/dotfiles/nix/nix/.#air   # or .#main

# Update all packages
cd ~/dotfiles/nix/nix && nix flake update && sudo darwin-rebuild switch --flake '.#air'

# Check what will change (dry run)
sudo darwin-rebuild build --flake ~/dotfiles/nix/nix/.#air

# Clean up old generations (frees disk space)
sudo nix-collect-garbage -d

# See all nix-darwin options
man configuration.nix
```

## Migration to New Machine

1. Install Nix: `sh <(curl -L https://nixos.org/nix/install)`
2. Enable flakes: `mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`
3. Clone dotfiles: `git clone https://github.com/bragur/dotfiles.git ~/dotfiles`
4. Bootstrap nix-darwin: `cd ~/dotfiles/nix/nix && sudo nix run nix-darwin -- switch --flake '.#air'` (or `'.#main'`)
5. Symlink configs: `cd ~/dotfiles && stow zsh git zsh-abbr mise tmux oh-my-posh ghostty atuin`
6. Post-stow: `mkdir -p ~/Pictures/Screenshots && mise install`
7. Restart shell: `exec zsh`

**Note**: The first-time bootstrap uses `nix run nix-darwin` because `darwin-rebuild` doesn't exist yet. After this initial setup, use `darwin-rebuild switch` for all future updates.

## Philosophy

This setup follows a **hybrid approach**:

- **Nix-darwin**: Infrastructure as code - system packages, settings, Homebrew integration
- **Homebrew**: GUI applications and tools that need macOS-specific integration
- **mise**: Development tools (Node, Python, etc.) - flexible per-project versions
- **stow**: Dotfiles - directly editable configs (zsh, tmux, etc.)
