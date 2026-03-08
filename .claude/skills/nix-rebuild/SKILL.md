---
name: nix-rebuild
description: Rebuild nix-darwin system configuration with validation and dry-run preview
disable-model-invocation: true
---

# Nix Rebuild

Rebuild the nix-darwin system configuration safely.

## Steps

1. **Validate the flake** before attempting any rebuild:
   ```bash
   cd ~/dotfiles/nix/nix && nix flake check
   ```
   If validation fails, stop and report the errors.

2. **Show what will change** with a dry-run build:
   ```bash
   sudo darwin-rebuild build --flake ~/dotfiles/nix/nix/.#air
   ```
   Summarize the key changes (new packages, removed packages, updated versions).

3. **Ask the user to confirm** before applying changes.

4. **Apply the rebuild**:
   ```bash
   cd ~/dotfiles/nix/nix && sudo darwin-rebuild switch --flake '.#air'
   ```

5. **Verify success** by checking the generation number:
   ```bash
   darwin-rebuild --list-generations | tail -3
   ```

6. If anything goes wrong, remind the user they can rollback:
   ```bash
   sudo darwin-rebuild --rollback
   ```
