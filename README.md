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

1. **Install Nix**:

   ```sh
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. **Clone dotfiles**:

   ```sh
   git clone git@github.com:bragur/dotfiles.git ~/dotfiles
   ```

3. **Apply nix-darwin configuration** (currently on `air` branch for MacBook Air):

   ```sh
   cd ~/dotfiles/nix/nix
   sudo darwin-rebuild switch --flake '.#air'
   ```

4. **Symlink configs with stow**:

   ```sh
   cd ~/dotfiles
   stow zsh        # Symlinks zsh configs
   stow nvim-distros  # Symlinks neovim configs
   stow zsh-abbr   # Symlinks zsh abbreviations
   ```

5. **Restart shell**:
   ```sh
   exec zsh
   ```

### Updating the System

```sh
# Update everything (Nix packages, Homebrew, system settings)
cd ~/dotfiles/nix/nix
nix flake update
sudo darwin-rebuild switch --flake '.#air'

# Update dev tools
mise upgrade
```

For detailed nix-darwin usage, see **[nix/nix/README.md](nix/nix/README.md)**.

## Stow Usage

Each directory in the root is a "package" that mirrors your home directory structure:

```sh
# Link specific configs
stow zsh          # zsh/.zshrc -> ~/.zshrc
stow nvim-distros # nvim-distros/.config/nvim -> ~/.config/nvim

# Unlink configs
stow -D zsh       # Remove symlinks
```

## Configurations

### Theme

I've been experimenting with [Catppuccin](https://github.com/catppuccin/catppuccin), the soothing pastel theme for the high-spirited. It tunes in nicely with [tmux](https://github.com/tmux/tmux/wiki) and [Neovim](https://neovim.io/).

### System Management

#### [nix-darwin](https://github.com/LnL7/nix-darwin)

The system is managed declaratively using nix-darwin. This means packages, Homebrew apps, and macOS settings are all defined in `nix/nix/flake.nix`. To add a package or change settings, edit the flake and rebuild. See **[nix/nix/README.md](nix/nix/README.md)** for details.

Currently configured for the `air` machine (MacBook Air). Eventually, I'd like to sync this setup with my work machine for identical configurations across devices.

**Homebrew Usage**: Homebrew is managed by nix-darwin with `onActivation.cleanup = "zap"`. This means:

- Packages declared in `flake.nix` are permanent
- Running `brew install something` is **temporary** - it will be removed on the next `darwin-rebuild`
- This keeps the system clean and ensures everything is tracked in code

#### [mise](https://mise.jdx.dev/)

Development tools (Node.js, Python, Yarn, etc.) are managed with mise, allowing per-project version management. Global tools are configured in `~/.config/mise/config.toml`. Project-specific versions can be set with `.mise.toml` files.

### Terminal

#### [Ghostty](https://ghostty.org/)

Running Ghostty as my terminal emulator. It's fast, GPU-accelerated, and handles large screens with multiple panes smoothly - something I struggled with in iTerm2 with my Neovim/tmux setup.

### [zsh](https://www.zsh.org/)

#### [Antidote](https://getantidote.github.io/)

I run the Z shell with antidote for plugin management. Configured plugins include:

- `zsh-abbr` - Command abbreviations (223 custom abbreviations)
- `zsh-autosuggestions` - Fish-like autosuggestions
- `fast-syntax-highlighting` - Syntax highlighting
- `zsh-fzf-history-search` - Fuzzy history search
- Various oh-my-zsh plugins (git, colored-man-pages, etc.)

#### [oh-my-posh](https://ohmyposh.dev/)

Using oh-my-posh for the prompt, configured with a custom theme.

#### [tmux](https://github.com/tmux/tmux/wiki)

I run tmux as a multiplexer for session management and to stay terminal emulator agnostic. Key maps for pane navigation are identical to my Neovim bindings, making navigation between panes seamless.

The status line uses the Catppuccin theme with battery, CPU status, and time. It's configured to be on top.

#### [tmuxifier](https://github.com/jimeh/tmuxifier)

Complimenting tmux is tmuxifier where I have a set of layouts to easily be able to start up my ideal environments, i.e. something like Neovim on the left and then a couple of stacked panes on the right, one with a watching compiler and my web server below that. This I can then toggle in and out, especially when moving to a laptop screen. It's useful for larger screens as well as sometimes I might add another pane between my two main sections to run tests and it's quite handy to be able to get those informational screens out of the way when my brain cells need some space.

### [Neovim](https://neovim.io/)

I run a little configuration on top of [LazyVim](https://www.lazyvim.org/) adding seamless navigation between windows in Neovim and to tmux panes and back. I feel the built in terminals for Neovim are a little fiddly so I rely more on tmux for my workflow and it rocks for my purposes. You will find my specific config [here](https://github.com/bragur/dotfiles/tree/main/nvim-distros/.config/nvim-distros/lazyvim/lua). My [keymaps](https://github.com/bragur/dotfiles/tree/main/nvim-distros/.config/nvim-distros/lazyvim/lua/config/keymaps.lua) serve the use case of my Icelandic keyboard layout. Specifially any bindings to the option modifier key will be specific to that layout so they will should be reconfigured before usage or they will most likely be useless.

```

```
