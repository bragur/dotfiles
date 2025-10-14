# Work Machine Migration Guide

## Pre-Migration Backups

### Critical Backups
- [ ] **SSH keys**: Back up entire `~/.ssh/` directory (especially private keys without `.pub` extension)
  - **IMPORTANT**: Store in a secure location (encrypted USB, password manager, etc.)
  - Private keys: `id_rsa`, `id_ed25519`, etc.
  - Public keys can be regenerated but easier to backup everything
- [ ] **GPG keys** (if used for signing commits):
  ```bash
  # Export private keys (REQUIRED)
  gpg --export-secret-keys -a > gpg-private-backup.asc
  # Export public keys
  gpg --export -a > gpg-public-backup.asc
  # Export trust database
  gpg --export-ownertrust > gpg-trust-backup.txt
  ```
  - **IMPORTANT**: Store private key backup in a secure location
- [ ] **Shell history**: `.zsh_history`, `.bash_history`
- [ ] **Git config**:
  - Check `~/.gitconfig` for work email/credentials
  - Check `git config --local` in important repos
- [ ] **Environment secrets**: Any `.env` files, API keys, credentials
- [ ] **Application data**: IDE settings, database dumps, etc.

### Nice to Have
- [ ] `brew leaves > ~/backup-brew-leaves.txt` - reference of installed packages
- [ ] `brew services list > ~/backup-brew-services.txt` - running services
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

### 4. Restore Work-Specific Configs
- [ ] Restore SSH keys
- [ ] Update git config with work email if needed
- [ ] Restore any environment secrets
- [ ] Configure work-specific settings

## Notes
- Since both machines use stow, transition should be smooth
- Nix flake will handle package management cleanly
- No more dual homebrew architecture issues
