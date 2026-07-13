# bragur's Dotfiles

## Introduction

This repository contains dotfiles for various applications and services which I use in my personal daily workflow. It is catered to web development, specifically and mainly in [ReScript](https://rescript-lang.org/). While I strive to be a zero config guy in most cases I'm also enthralled with tinkering and polishing and thus my dotfiles came to life. I don't necessarily swap machines very often in my professional career but I'd still like for this configuration to be both easily manageable and quickly set up should I find myself in front of a new computer. I also run my shell on a powerful workstation via [Tailscale](https://tailscale.com/) and ssh from my MacBook Air, achieving a light, portable and powerful setup from anywhere. It's awesome!

## Setup Philosophy

This configuration uses a **hybrid approach** for maximum flexibility:

- **[nix-darwin](https://github.com/LnL7/nix-darwin)** - Declarative system configuration (packages, Homebrew, macOS settings)
- **[mise](https://mise.jdx.dev/)** - Per-project development tool versions (Node.js, Python, etc.)
- **[stow](https://www.gnu.org/software/stow/)** - Dotfile management (directly editable configs)
- **[Homebrew](https://brew.sh/)** - GUI applications (managed by nix-darwin)

This gives you infrastructure-as-code for reproducibility while keeping configs easily editable and dev tools flexible.

## Quick Start

### Initial Setup

1. **Clone dotfiles**:

   ```sh
   git clone https://github.com/bragur/dotfiles.git ~/dotfiles
   ```

2. **Run the bootstrap script**:

   ```sh
   cd ~/dotfiles && ./bootstrap.sh
   ```

   The script is idempotent — every step skips itself if already done. It:

   - Installs Nix via the [Determinate Systems installer](https://determinate.systems/nix-installer/) (flakes enabled by default, correct macOS SSL cert path). If nix is already present it is **never** reinstalled — re-running an installer over an existing install can break the machine.
   - Bootstraps nix-darwin with `.#main` (skipped if the machine already has a nix-darwin system, e.g. when setting up a second macOS account).
   - Stows all config packages: `atuin claude ghostty git karabiner mise nvim oh-my-posh tmux zsh zsh-abbr zsh-abbr-hint`. Conflicting real files are backed up to `~/dotfiles-backup-<timestamp>/`.
   - Runs `mise install` for dev tools (Node.js, etc.).

3. **Manual follow-ups** (the script prints these too):

   ```sh
   atuin login && atuin sync   # shell history sync
   gh auth login               # GitHub CLI
   tmux                        # TPM auto-installs; then prefix + I (Ctrl-a then Shift-i) to install plugins
   exec zsh                    # restart shell
   ```

4. **Verify**:

   ```sh
   ./doctor.sh
   ```

   Read-only health check: required commands, stow symlinks, shell startup, plugin loading.

See **[BOOTSTRAP.md](BOOTSTRAP.md)** for details, including setting up a second macOS account on an already-nix-managed machine and what to do if your account name isn't `bragur`.

### Updating the System

```sh
# Update everything (Nix packages, Homebrew, system settings)
cd ~/dotfiles/nix/nix
nix flake update
sudo darwin-rebuild switch --flake '.#air'   # or '.#main' on Mac Mini

# Update dev tools
mise upgrade
```

For detailed nix-darwin usage, see **[nix/nix/README.md](nix/nix/README.md)**.

## Stow Usage

Each directory in the root is a "package" that mirrors your home directory structure:

```sh
# Link specific configs
stow zsh          # zsh/.zshrc -> ~/.zshrc
stow git          # git/.gitconfig -> ~/.gitconfig

# Unlink configs
stow -D zsh       # Remove symlinks
```

## Configurations

### Theme

I've been experimenting with [Catppuccin](https://github.com/catppuccin/catppuccin), the soothing pastel theme for the high-spirited. It tunes in nicely with [tmux](https://github.com/tmux/tmux/wiki), [Ghostty](https://ghostty.org/), and [Neovim](https://neovim.io/).

**Font**: [Maple Mono NF](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/MapleMono) (Nerd Font variant) - installed via nix-darwin for proper icon support in tmux and other tools.

### System Management

#### [nix-darwin](https://github.com/LnL7/nix-darwin)

The system is managed declaratively using nix-darwin. This means packages, Homebrew apps, and macOS settings are all defined in `nix/nix/flake.nix`. To add a package or change settings, edit the flake and rebuild. See **[nix/nix/README.md](nix/nix/README.md)** for details.

The flake exposes two configuration names, `main` and `air`, that point at the **same machine-agnostic configuration** — either works on any Apple Silicon Mac.

**Homebrew Usage**: Homebrew is managed by nix-darwin with `onActivation.cleanup = "zap"`. This means:

- Packages declared in `flake.nix` are permanent
- Running `brew install something` is **temporary** - it will be removed on the next `darwin-rebuild`
- This keeps the system clean and ensures everything is tracked in code

#### [mise](https://mise.jdx.dev/)

Development tools (Node.js, Python, Yarn, etc.) are managed with mise, allowing per-project version management. Global tools are configured in `~/.config/mise/config.toml`. Project-specific versions can be set with `.mise.toml` files.

### Terminal

#### [Ghostty](https://ghostty.org/)

Running Ghostty as my terminal emulator. It's fast, GPU-accelerated, and handles large screens with multiple panes smoothly - something I struggled with in iTerm2 with my Neovim/tmux setup.

Configured with:
- **Font**: Maple Mono NF (Nerd Font)
- **Theme**: Catppuccin Mocha
- **Window padding**: 8px for comfortable spacing

Configuration: `ghostty/.config/ghostty/config`

### [zsh](https://www.zsh.org/)

#### [Antidote](https://getantidote.github.io/)

I run the Z shell with antidote for plugin management. Configured plugins include:

- `zsh-abbr` - Command abbreviations (223+ custom abbreviations)
- `zsh-autosuggestions` - Fish-like autosuggestions
- `fast-syntax-highlighting` - Syntax highlighting
- oh-my-zsh plugins (colored-man-pages, globalias)

#### [oh-my-posh](https://ohmyposh.dev/)

Using oh-my-posh for the prompt with a custom Catppuccin-themed configuration. The theme shows:
- Current directory (in blue)
- Git status with branch, changes, and upstream info (in rounded pills)
- Execution time for slow commands (>5s)
- Node.js and Python versions when relevant
- Root indicator

Configuration: `oh-my-posh/.config/oh-my-posh/config.toml`

#### [tmux](https://github.com/tmux/tmux/wiki)

I run tmux as a multiplexer for session management and to stay terminal emulator agnostic. Key maps for pane navigation are identical to my Neovim bindings, making navigation between panes seamless.

The status line uses the Catppuccin theme with battery, CPU status, and time. It's configured to be on top.

#### [tmuxifier](https://github.com/jimeh/tmuxifier)

Complimenting tmux is tmuxifier where I have a set of layouts to easily be able to start up my ideal environments, i.e. something like Neovim on the left and then a couple of stacked panes on the right, one with a watching compiler and my web server below that. This I can then toggle in and out, especially when moving to a laptop screen. It's useful for larger screens as well as sometimes I might add another pane between my two main sections to run tests and it's quite handy to be able to get those informational screens out of the way when my brain cells need some space.

### [Neovim](https://neovim.io/)

I run a configuration based on [LazyVim](https://www.lazyvim.org/) with seamless navigation between Neovim windows and tmux panes. The built-in terminals in Neovim didn't fit my workflow, so I rely on tmux instead.

**Note**: My [keymaps](https://github.com/bragur/dotfiles/tree/main/nvim/.config/nvim/lua/config/keymaps.lua) are optimized for an Icelandic keyboard layout. Option key bindings will need to be reconfigured for other layouts.

## Troubleshooting

### Nix Store volume not mounted after reboot

If after a reboot you see `command not found` for nix, stow, and other tools, the Nix Store APFS volume may have mounted at `/Volumes/Nix Store` instead of `/nix`:

```sh
mount | grep -i nix    # Check where it mounted
```

Fix by remounting:

```sh
# Find the disk identifier
diskutil list | grep -i nix

# Remount at /nix (replace disk3s7 with your identifier)
sudo diskutil mount -mountPoint /nix disk3s7
```

Then rebuild to fix it permanently:

```sh
sudo darwin-rebuild switch --flake ~/dotfiles/nix/nix/.#air
```

### Nix daemon not starting (SSL cert errors)

If the nix daemon can't download from the cache due to SSL errors, the cert path in the LaunchDaemon may be wrong:

```sh
# Check the current config
sudo cat /Library/LaunchDaemons/org.nixos.nix-daemon.plist | grep -A1 SSL

# If missing or pointing to a nonexistent path, add/fix it
sudo /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
sudo /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:NIX_SSL_CERT_FILE string /etc/ssl/cert.pem" /Library/LaunchDaemons/org.nixos.nix-daemon.plist

# Restart the daemon
sudo launchctl bootout system/org.nixos.nix-daemon
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

### Nuclear option: full nix reinstall

If the Nix Store volume is encrypted/locked and unrecoverable:

```sh
# 1. Delete the broken volume
sudo diskutil apfs deleteVolume disk3s7   # use your disk identifier

# 2. Reinstall nix (Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 3. Restart terminal, then re-run the bootstrap (handles nix-darwin + stow)
cd ~/dotfiles && ./bootstrap.sh
```