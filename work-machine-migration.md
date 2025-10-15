# Work Machine Migration Guide

> **Note**: This guide is for refreshing homebrew and dotfiles on an existing machine (not a full wipe). Your SSH keys, GPG keys, and existing configs will remain untouched since they're not in the dotfiles repo.

## Pre-Migration Backups

### Optional Backups (for reference)
- [ ] `brew leaves > ~/backup-brew-leaves.txt` - reference of currently installed packages
- [ ] `brew services list > ~/backup-brew-services.txt` - currently running services
- [ ] **Shell history** (optional): `.zsh_history`, `.bash_history` - in case something goes wrong
- [ ] Custom scripts in `/usr/local/bin` not in dotfiles

## Homebrew Cleanup

### 1. Check for Dual Installation
```bash
ls -la /usr/local/Homebrew
ls -la /opt/homebrew
which -a brew
```

### 2. Remove ARM Homebrew (if exists)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### 3. Remove Intel Homebrew (if exists)
```bash
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### 4. Clean Up Remaining Files
```bash
sudo rm -rf /opt/homebrew
sudo rm -rf /usr/local/Homebrew
sudo rm -rf /usr/local/Caskroom
sudo rm -rf /usr/local/Cellar
# Check for any remaining homebrew-related dirs in /usr/local
ls /usr/local
```

## Dotfiles Migration

### 1. Clone Dotfiles Repo
```bash
cd ~
git clone <your-repo-url> dotfiles
cd dotfiles
```

### 2. Setup Nix
Follow nix installation and setup instructions

### 3. Setup with Stow
```bash
# Review and apply stow configs
stow <package-name>
```

### 4. Verify Everything Works
- [ ] Test SSH connections to work services
- [ ] Verify git commits use correct email
- [ ] Check work-specific tools/services are running

## Notes
- Since both machines use stow, transition should be smooth
- Nix flake will handle package management cleanly
- No more dual homebrew architecture issues
