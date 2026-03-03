# Work Machine Migration Guide

> **Note**: This guide is for refreshing homebrew and dotfiles on an existing machine (not a full wipe). Your SSH keys, GPG keys, and existing configs will remain untouched since they're not in the dotfiles repo.

## Pre-Migration Backups

### Optional Backups (for reference)
- [ ] `brew leaves > ~/backup-brew-leaves.txt` - reference of currently installed packages
- [ ] `brew services list > ~/backup-brew-services.txt` - currently running services
- [ ] **Shell history** (optional): `.zsh_history`, `.bash_history` - in case something goes wrong
- [ ] Custom scripts in `/usr/local/bin` not in dotfiles

## Homebrew Cleanup

### 1. Check for Existing Installation
```bash
which -a brew
ls -la /opt/homebrew
```

### 2. Remove Homebrew (if exists)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### 3. Clean Up Remaining Files
```bash
sudo rm -rf /opt/homebrew
# Check for any remaining homebrew-related dirs
ls /usr/local
```

## Dotfiles Migration

### 1. Install Nix
```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Enable Flakes
```bash
mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 3. Clone Dotfiles Repo
```bash
git clone https://github.com/bragur/dotfiles.git ~/dotfiles
```

### 4. Move macOS shell configs
```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

### 5. Bootstrap nix-darwin
```bash
cd ~/dotfiles/nix/nix
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake '.#air'   # or '.#main' for Mac Mini
```

### 6. Symlink Configs with Stow
```bash
cd ~/dotfiles
stow zsh git zsh-abbr mise tmux oh-my-posh ghostty atuin
```

### 7. Install Dev Tools
```bash
mise install
```

### 8. Restart Shell
```bash
exec zsh
```

### 9. Verify Everything Works
- [ ] Test SSH connections to work services
- [ ] Verify git commits use correct email
- [ ] Check work-specific tools/services are running

## Notes
- Since both machines use stow, transition should be smooth
- Nix flake will handle package management cleanly
- Homebrew is managed by nix-darwin — manual `brew install` is temporary and will be removed on next rebuild
