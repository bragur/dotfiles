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

2. **Show what will change** with a build (no sudo needed) and a closure diff:
   ```bash
   cd ~/dotfiles/nix/nix && darwin-rebuild build --flake '.#main' \
     && nix store diff-closures /run/current-system ./result; rm -f result
   ```
   Summarize the key changes: added and removed packages, major version bumps, and notable updates.

3. **Ask the user to confirm** before applying changes.

4. **Apply the rebuild.** `switch` needs sudo, and the agent's shell cannot answer a password prompt. Ask the user to run it in the prompt with the `!` prefix:
   ```bash
   ! cd ~/dotfiles/nix/nix && sudo darwin-rebuild switch --flake '.#main'
   ```
   Wait for its output before continuing.

5. **Verify success** by checking the generation number:
   ```bash
   darwin-rebuild --list-generations | tail -3
   ```

6. If anything goes wrong, remind the user they can rollback:
   ```bash
   sudo darwin-rebuild --rollback
   ```
