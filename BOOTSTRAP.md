# Bootstrap Guide

How to go from a blank Mac (or a fresh macOS account) to a fully working setup
using this repo. The heavy lifting is done by two scripts at the repo root:

- **`./bootstrap.sh`** — idempotent setup: nix, nix-darwin, stow, mise. Every
  step skips itself if already done, so it is always safe to re-run.
- **`./doctor.sh`** — read-only health check. Run it whenever something feels
  off; it exits non-zero if a required check fails.

## Fresh Mac

1. Install Xcode Command Line Tools (bootstrap will remind you if missing):

   ```sh
   xcode-select --install
   ```

2. Clone and bootstrap:

   ```sh
   git clone https://github.com/bragur/dotfiles.git ~/dotfiles
   cd ~/dotfiles && ./bootstrap.sh
   ```

   What it does, in order:

   - **Nix** — installed via the [Determinate Systems installer](https://determinate.systems/nix-installer/)
     (flakes on by default, correct macOS SSL cert path, reliable daemon).
     If nix is already present (`nix` on PATH or `/nix/store` exists) the
     installer is **never** re-run — see "Second account" below.
   - **nix-darwin** — `sudo nix run nix-darwin -- switch --flake '.#main'`
     (skipped if `/run/current-system` already exists). This installs all
     system packages, Homebrew casks, fonts, and macOS settings.
   - **Stow** — symlinks all config packages
     (`atuin claude ghostty git karabiner mise nvim oh-my-posh tmux zsh zsh-abbr zsh-abbr-hint`).
     Conflicting real files are moved to `~/dotfiles-backup-<timestamp>/` first.
   - **mise** — installs dev tool versions (Node.js, Python) from
     `~/.config/mise/config.toml`.

3. Manual follow-ups (bootstrap prints this checklist at the end):

   ```sh
   atuin login && atuin sync   # shell history sync across machines
   gh auth login               # GitHub CLI
   tmux                        # TPM auto-installs; then prefix + I to install plugins
   exec zsh                    # restart shell with everything in place
   ```

4. Verify:

   ```sh
   ./doctor.sh
   ```

## Second account on an already-nix-managed machine

**Do NOT run the nix installer again.** Nix is a global multi-user install;
re-running the installer over an existing one has badly broken a machine
before. `bootstrap.sh` guards against this automatically:

- nix already present → install skipped
- `/run/current-system` exists → nix-darwin system bootstrap skipped

So for a second macOS account, just clone and run `./bootstrap.sh` — only the
user-level steps (stow, mise) execute, and **no sudo is needed**.

## If your macOS account name differs

The flake hardcodes the account name in one place — the `username = "..."`
line near the top of `nix/nix/flake.nix`. It feeds `system.primaryUser`,
the Homebrew prefix owner, and the dock setup paths.

`bootstrap.sh` checks this before bootstrapping a new system: if `$USER`
doesn't match and no nix-darwin system exists yet, it stops and tells you to
edit that line first.

## Notes

- **Node comes from mise**, not nix. Anything that needs `node` (e.g. the
  Claude Code statusline, which will render blank) won't work until
  `mise install` has run and the shell has been restarted.
- **atuin** starts with an empty local history until `atuin login && atuin sync`.
- **Flake config names**: `.#main` and `.#air` point at the same
  machine-agnostic configuration — either works on any Apple Silicon Mac.
- **Homebrew cleanup**: nix-darwin manages Homebrew with
  `onActivation.cleanup = "zap"` — anything installed manually with
  `brew install` is removed on the next `darwin-rebuild switch`. Add it to
  `nix/nix/flake.nix` to keep it.
- **Machine-local shell config** stays out of the repo: `~/.config/zsh/local.zsh`
  (functions, startup hooks) and `~/.config/zsh-abbr/local-abbreviations`
  (session-scope `abbr -S -f` entries) are sourced if present and are
  gitignored — per-machine/work config belongs there.
