---
status: ready
---

# Spec: zsh-abbr-hint — live abbreviation validation and expansion preview

## Problem Statement
While typing a zsh-abbr abbreviation (e.g. `gst`), fast-syntax-highlighting (F-Sy-H) colors it red as an `unknown-token`, because the word is not a real command until it expands on space/enter. Two things are missing:

1. **No positive signal.** A valid abbreviation looks identical to a typo — both render red. The user has no in-the-moment confirmation that `gst` is a real abbreviation.
2. **No preview.** With 233+ regular abbreviations, the user cannot recall what every abbreviation expands to without hitting space and watching it replace.

We want a valid abbreviation in command position to render **green** (overriding F-Sy-H's red), and a **dim `→ expansion` hint** to appear on the right of the line while editing.

## Proposed Solution
A new standalone stow package, `zsh-abbr-hint/`, providing a single plugin file that:

- Registers a `line-pre-redraw` ZLE hook **after** F-Sy-H has bound its widgets, so our hook runs after F-Sy-H rebuilds `region_highlight`.
- Shares one `(qqq)`-aware lookup function that maps a word → `(is-abbr?, expansion)` across regular (command-position), global (anywhere), and session abbreviation arrays.
- **Part A:** appends a green `region_highlight` span over the command-position word when it is a known abbreviation, overriding F-Sy-H's red.
- **Part B:** sets `RPROMPT` to a dimmed `→ <expansion>` while editing a known abbreviation, and restores oh-my-posh's RPROMPT on accept/clear.

The feature ships **staged**: Part A first, gated on a zpty precedence test that proves our green wins over F-Sy-H's red *under realistic deferred-load timing*; Part B builds on the same lookup + hook.

## User Stories
- As a shell user, when I type a valid abbreviation in command position (`gst`), I see it turn green so I know it will expand.
- As a shell user, when I type a valid abbreviation, I see a dim `→ git status` on the right so I know what it expands to before committing.
- As a shell user, when I type a typo (`gsx`), it stays red — the green signal is reserved for real abbreviations.
- As a shell user, when I type `echo gst`, `gst` is **not** recolored and **no** hint shows — `gst` is an argument, not a command.
- As a shell user, when I accept the line or clear it, oh-my-posh's right-hand segment (node/python) returns unchanged.
- As a shell user, when I use a global abbreviation and press space (globalias expands it), the hint disappears and no stale green remains on the expanded text.

## Technical Approach

### Architecture
The feature is a leaf ZLE plugin layered on top of three existing components, all loaded by antidote (`zsh/.zsh_plugins.txt`):

- `olets/zsh-abbr` (`kind:defer`) — owns the abbreviation arrays.
- `zdharma-continuum/fast-syntax-highlighting` (`kind:defer`) — owns `region_highlight` per redraw.
- oh-my-posh (eval'd in `zsh/.zshrc` after antidote) — owns `RPROMPT`.

**Load-order discovery (load-bearing — this is the crux of Part A).**

F-Sy-H does **not** use `add-zle-hook-widget`. It wraps every editing ZLE widget so each invocation calls `_zsh_highlight`, which **resets** `region_highlight=()` and rebuilds it (`fast-syntax-highlighting.plugin.zsh`: function `_zsh_highlight` at line 66, `region_highlight=()` at line 74, widget wrapping in `_zsh_highlight_bind_widgets` near line 240). Critically, `_zsh_highlight_bind_widgets` **explicitly excludes** `zle-line-pre-redraw` from the widgets it wraps (the exclusion glob at line 242: `…|zle-line-pre-redraw|…`). It also defines the function `_zsh_highlight` at source time, which is the sentinel we use to detect that F-Sy-H is loaded.

Per-keystroke timeline: a keystroke invokes a F-Sy-H-wrapped editing widget → the wrapped body calls `_zsh_highlight` → `region_highlight` is reset and repopulated (the `gst` word now carries F-Sy-H's red `unknown-token` span). ZLE then runs the `line-pre-redraw` hook chain before painting. Our hook is in that chain, runs **after** `_zsh_highlight` has populated `region_highlight`, and **appends** a green span. The terminal renders overlapping spans last-wins, so our later green span wins over F-Sy-H's red. This is the precedence theory; it MUST be proven by the precedence test (Tier 2) before Part A proceeds.

**The kind:defer problem (load-bearing).** In `zsh/.zsh_plugins.txt`, F-Sy-H is loaded `kind:defer`. Antidote translates each `kind:defer` entry into a `zsh-defer source <plugin-file>` call. `zsh-defer` (`romkatv/zsh-defer`) maintains a **single FIFO queue** (`_zsh_defer_tasks`, see `zsh-defer.plugin.zsh` function `_zsh-defer-resume`): queued tasks run, in queue order, only once ZLE is idle after the first prompt. Therefore F-Sy-H's widget wrapping does **not** happen during `antidote load` — it happens asynchronously after the first prompt. Sourcing our plugin at the end of `antidote.zsh` (immediately after `antidote load`) would register our `line-pre-redraw` hook **before** F-Sy-H wraps its widgets, defeating the precedence theory. The original spec's "source after antidote load" wiring is therefore wrong for this repo.

**Chosen registration strategy: deferred registration guarded by a one-shot precmd (primary).** We register our hook from a self-removing `precmd` hook (`_zah_register`) that guards on F-Sy-H being loaded. Rationale: zsh-defer flushes its queue while ZLE is idle, and a `precmd` hook is the canonical "after the prompt is about to be (re)drawn" point. By the time our `precmd` fires on the **second** prompt (i.e. after the first command line, or after the deferred queue has drained on the first idle window), F-Sy-H's deferred `source` has run and `_zsh_highlight` is defined.

```zsh
autoload -Uz add-zsh-hook
_zah_register() {
  # Wait until F-Sy-H's deferred source has run (it defines _zsh_highlight
  # and has already wrapped the editing widgets by this point).
  (( $+functions[_zsh_highlight] )) || return 0     # F-Sy-H not yet loaded; try next precmd
  (( $+functions[add-zle-hook-widget] )) || return 0
  add-zle-hook-widget line-pre-redraw _zah_redraw
  add-zle-hook-widget zle-line-finish _zah_restore_rprompt
  add-zsh-hook -d precmd _zah_register               # one-shot: self-remove after success
}
add-zsh-hook precmd _zah_register
```

This is robust regardless of how many idle windows zsh-defer needs to drain its queue: `_zah_register` simply no-ops and waits for the next `precmd` until `_zsh_highlight` exists, then registers and removes itself. It does **not** depend on antidote/zsh-defer preserving any particular relative ordering, and it does not depend on F-Sy-H having finished before the *first* prompt.

**Why this beats the alternatives.**
- *Alternative (a): add `zsh-abbr-hint` to `.zsh_plugins.txt` as a local `kind:defer` entry placed after fast-syntax-highlighting.* zsh-defer's FIFO queue does preserve relative order, so this would also work in principle. We reject it as the primary because it couples correctness to antidote's translation of a local path entry into a defer task at the right queue position, and because a local non-git plugin entry is a less obvious, less testable contract than an explicit guard. We keep it documented as the **fallback** if the precmd approach ever proves flaky.
- *Alternative (c): a fixed-count guarded retry / sleep.* Rejected — timing-fragile and exactly the flaky-sleep pattern the test tier forbids.

The precmd guard is the committed primary; the `kind:defer` local entry is the fallback. Either way, the precedence requirement (our registration after F-Sy-H wraps widgets) is satisfied and is proven by Tier 2.

**Contingency if precedence still fails at render time.** If, even with correct ordering, appending a later green span does not win at render time, fall back to overriding F-Sy-H's `unknown-token` styling for known abbreviations. Two ordered options: (1) a small F-Sy-H chroma/`fast-theme` rule keyed on our lookup, or (2) a post-pass that locates F-Sy-H's `unknown-token` span over the command word and rewrites its style in place. The overlay-append remains the primary design; this contingency is only taken if Tier 2 shows append losing.

### Package layout and in-package path
The package is a stow package whose tree mirrors the home directory. The plugin is shell config, so it lives under `.config/zsh/` (the same directory `$ZSH_HOME` points at, `~/.config/zsh`, per `zsh/.zshrc` line 1):

```
zsh-abbr-hint/
  .config/zsh/zsh-abbr-hint.plugin.zsh   # the plugin (stows to ~/.config/zsh/)
  tests/
    lib.zsh                              # shared test helpers (zpty drain loop)
    test_lookup.zsh                      # unit: lookup core, no TTY
    test_precedence.zsh                  # integration: green beats F-Sy-H red (deferred-order timing)
    test_hint.zsh                        # integration: RPROMPT hint set/restore + globalias
    run.zsh                              # runs all of the above
  README.md
```

**Justification.** Placing the plugin at `~/.config/zsh/zsh-abbr-hint.plugin.zsh` keeps it inside `$ZSH_HOME`, where all sourced shell modules already live, and lets the wiring use the existing `$ZSH_HOME` variable. `stow zsh-abbr-hint` from `~/dotfiles` symlinks it into place exactly like the other zsh modules. We do **not** register the plugin's *hooks* by sourcing it after `antidote load`, because F-Sy-H is `kind:defer` and is not yet loaded at that point (see Load-order discovery). The file is sourced early (to define functions and install the one-shot `precmd`), but the `line-pre-redraw` hook itself is registered later, by `_zah_register`, only once F-Sy-H is present.

### Wiring point
Source the plugin from `zsh/.zshrc`, **after** the oh-my-posh init block (after line 38), not from `antidote.zsh`:

```zsh
# zsh-abbr-hint: defines functions + installs a one-shot precmd that registers
# its line-pre-redraw hook AFTER fast-syntax-highlighting (kind:defer) has loaded.
[[ ! -f $ZSH_HOME/zsh-abbr-hint.plugin.zsh ]] || source $ZSH_HOME/zsh-abbr-hint.plugin.zsh
```

`$ZSH_HOME` is set on `.zshrc` line 1 (`export ZSH_HOME="$HOME/.config/zsh"`) and is therefore guaranteed defined at this source point (it is already used by the module sources on lines 8–12). Sourcing here, after oh-my-posh's `eval "$(oh-my-posh init zsh …)"` (line 35), has a second benefit the reviewer noted: oh-my-posh's prompt machinery and precmd are already installed, so Part B's lazy `RPROMPT` capture is straightforward — by the time `_zah_redraw` runs (during line editing), oh-my-posh's precmd has already computed `RPROMPT`. We still capture lazily at hook time (not at source time) because `RPROMPT` is recomputed each prompt; see Service Layer. Sourcing the file does **not** register any `line-pre-redraw` hook — registration is deferred to `_zah_register` so it lands after F-Sy-H's deferred load.

### Data Model Changes
No persistent data model changes. The plugin defines runtime state only:

- `_ZAH_RPROMPT_SAVED` (string, plugin-global) — last-seen oh-my-posh RPROMPT, captured lazily; empty until first capture.
- `_ZAH_LAST_HINT` (string, plugin-global) — last hint string rendered; used to avoid redundant `zle reset-prompt`. Defaults to empty.
- `_ZAH_HINT_ACTIVE` (int 0/1, plugin-global) — whether our hint currently owns RPROMPT. Defaults to 0.

No changes to `zsh-abbr/.config/zsh-abbr/user-abbreviations`.

### Service Layer
All functions are defined in `zsh-abbr-hint.plugin.zsh`, namespaced `_zah_`.

`_zah_register` — the one-shot `precmd` described under Architecture. Guards on `(( $+functions[_zsh_highlight] ))` and `(( $+functions[add-zle-hook-widget] ))`, registers the two ZLE hook widgets, then self-removes via `add-zsh-hook -d precmd _zah_register`. No-ops and retries on the next prompt until F-Sy-H is loaded.

`_zah_lookup <word>` — the shared core. Returns 0 if `<word>` is a known abbreviation, 1 otherwise. On success, sets `REPLY` to the unquoted expansion and `REPLY2` to the scope (`regular` or `global`). Probes, in order, using `(qqq)` key quoting on the probe and `(Q)` unquoting on the value (matching zsh-abbr at `zsh-abbr.zsh` lines 279–312):
  1. `ABBR_REGULAR_SESSION_ABBREVIATIONS` → scope `regular`
  2. `ABBR_REGULAR_USER_ABBREVIATIONS` → scope `regular`
  3. `ABBR_GLOBAL_SESSION_ABBREVIATIONS` → scope `global`
  4. `ABBR_GLOBAL_USER_ABBREVIATIONS` → scope `global`
  The `scope` out-parameter distinguishes `regular` vs `global`, because regular abbreviations are valid in command position only, while global abbreviations may match anywhere.

`_zah_command_word` — parses `$BUFFER` up to `$CURSOR` and returns the current command-position word plus a flag for whether the cursor word is in command position. Command position = first word of the line or first word after a separator `;`, `|`, `&&`, `||`, `&`, newline, or a `(`. Uses `${(z)BUFFER}` zsh lexer splitting and tracks separators so that `echo gst` reports `gst` as **not** command position. Global abbreviations bypass the command-position constraint but still respect token boundaries.

`_zah_redraw` — the single `line-pre-redraw` hook body, run as a **plain function** (not a ZLE widget; see Registration note). It runs both Part A (highlight) and Part B (hint) logic:
  - *Highlight (Part A):* computes the command-position word; if `_zah_lookup` reports a regular abbreviation in command position (or a global abbreviation at the cursor word), computes the word's byte offsets in `$BUFFER` and appends `region_highlight+=("$start $end fg=#a6e3a1,bold")`. Does nothing on no-match, leaving F-Sy-H's output intact.
  - *Hint (Part B):* if a known abbreviation is active, builds `hint="→ ${REPLY}"`. Compares to `_ZAH_LAST_HINT`; only when changed does it capture/restore and call `zle reset-prompt`:
    - On first activation, lazily capture oh-my-posh's RPROMPT: `_ZAH_RPROMPT_SAVED=$RPROMPT`. Set `RPROMPT="%F{#6c7086}${hint}%f"` and `_ZAH_HINT_ACTIVE=1`.
    - When the abbreviation is no longer active (no match / buffer cleared), restore `RPROMPT=$_ZAH_RPROMPT_SAVED`, set `_ZAH_HINT_ACTIVE=0`, and `zle reset-prompt`.
    - Update `_ZAH_LAST_HINT` and gate `zle reset-prompt` behind its change-check to avoid per-keystroke prompt thrash.

`_zah_restore_rprompt` — registered on `zle-line-finish`. When the line is accepted or aborted, if `_ZAH_HINT_ACTIVE`, restore `RPROMPT=$_ZAH_RPROMPT_SAVED`, reset `_ZAH_HINT_ACTIVE=0` and `_ZAH_LAST_HINT=""`. Because oh-my-posh recomputes RPROMPT in its own precmd each prompt, restoring on `zle-line-finish` (which fires while our hint may still be in `RPROMPT`) puts the saved value back, then oh-my-posh's next precmd overwrites it normally. This avoids fighting oh-my-posh for ownership across prompts.

**Registration (load-bearing — corrected).** `add-zle-hook-widget` accepts a **plain function name**; it does not require the function to be a ZLE widget created via `zle -N`. Our hooks run as plain function hooks, not standalone widgets. We therefore do **not** call `zle -N` for them:

```zsh
# Inside _zah_register, after the F-Sy-H guard passes:
add-zle-hook-widget line-pre-redraw _zah_redraw          # plain function hook
add-zle-hook-widget zle-line-finish  _zah_restore_rprompt # plain function hook
```

`_zah_redraw` runs in ZLE widget context (it may read `$BUFFER`/`$CURSOR`, mutate `region_highlight`, and call `zle reset-prompt`), which is valid for a `line-pre-redraw` hook function — `add-zle-hook-widget` invokes it via the hook machinery with ZLE context available. No `zle -N _zah_redraw` is needed or wanted (the previous `zle -N _zah_redraw _zah_redraw` two-arg form was redundant and misleading).

### View Layer
No new screens. Two on-line affordances:

- **Green recolor** of the command-position abbreviation via `region_highlight`.
- **Dim hint** `→ expansion` placed in `RPROMPT` (right-aligned), replacing oh-my-posh's right segment only while editing a known abbreviation.

## UI/UX Description
**Empty line.** Nothing changes; oh-my-posh RPROMPT (node/python) shows as usual.

**Typing a non-abbreviation (`gsx`).** Word renders in F-Sy-H's normal color (red `unknown-token` until it resolves to a real command). No hint. RPROMPT unchanged.

**Typing a known regular abbreviation in command position (`gst`).** As soon as the full word matches, `gst` turns green (Catppuccin Mocha green `#a6e3a1`, bold). The right side shows a dim `→ git status` (Catppuccin Mocha `overlay0` `#6c7086`). oh-my-posh's node/python segment is hidden for the moment.

**`echo gst`.** `gst` is an argument; it is not recolored and no hint appears.

**Global abbreviation mid-line.** If the cursor word is a global abbreviation, it may recolor/hint anywhere; pressing space triggers globalias, which expands the token — the buffer change re-fires our hook, the word no longer matches, and the hint clears with no stale green.

**Accepting the line (Enter).** The line expands/executes as normal; on the next prompt oh-my-posh's RPROMPT is restored.

**Clearing the line (Ctrl-C / Ctrl-U to empty).** Hint disappears and RPROMPT is restored to oh-my-posh's value.

## Edge Cases & Error Handling
- **F-Sy-H not yet loaded (deferred) at first prompt**: `_zah_register` no-ops on each `precmd` until `_zsh_highlight` is defined, then registers once and self-removes. No hook is installed prematurely, so no precedence violation; no error.
- **F-Sy-H never loaded** (e.g. partial shell): `_zah_register` simply keeps no-opping; the plugin stays inert. `region_highlight` append would still be safe, but we intentionally gate registration on F-Sy-H presence to honor the precedence contract.
- **zsh-abbr not loaded / arrays unset**: `_zah_lookup` treats unset arrays as empty (`${ABBR_*-}` guarded), returns 1, no recolor/hint. No error.
- **oh-my-posh not active** (Apple Terminal branch in `.zshrc` skips omp): `_ZAH_RPROMPT_SAVED` captures whatever `RPROMPT` is (possibly empty); restore writes it back. Hint still works.
- **Abbreviation key with special characters / spaces** (e.g. `"dotfiles pl"`): lookup uses `${(qqq)word}` so quoted keys match; multi-word keys are matched only when the parsed command token equals the key.
- **Cursor mid-word** (typing `gs` before completing `gst`): `gs` is itself a known abbreviation, so it recolors/hints for `gs`; this is correct behavior, not a bug.
- **Very long expansion**: RPROMPT is right-aligned and zsh truncates against the left prompt; we do not wrap. No special handling.
- **Redundant redraws**: `_ZAH_LAST_HINT` change-check gates `zle reset-prompt` so cursor moves without buffer change do not re-render the prompt.
- **Globalias overlap**: globalias (`plugins/globalias/globalias.plugin.zsh`) rebinds space to a widget that calls `zle _expand_alias; zle expand-word; zle self-insert`, mutating `$BUFFER`. The buffer change triggers a redraw, our `line-pre-redraw` hook re-runs against the expanded buffer, the old token no longer matches `_zah_lookup`, so the green span is not re-appended and the hint is restored. Our hint only previews and never calls expansion, so there is no double-expansion. This ordering (expansion mutates buffer → redraw → our hook sees expanded buffer) is verified by the Tier 3 globalias test case below.

## Performance Considerations
- 233+ abbreviations are stored in associative arrays; lookup is O(1) hash probe per array (≤4 probes), invoked once per redraw. Negligible.
- `${(z)BUFFER}` tokenization runs once per redraw on the pre-cursor buffer; bounded by line length.
- `zle reset-prompt` is the only expensive operation; it is gated behind the `_ZAH_LAST_HINT` change check so it fires at most once per hint transition, not per keystroke.
- `_zah_register` runs at most once per prompt until it succeeds, then self-removes — zero steady-state cost.
- No subprocess spawns, no disk I/O in the hot path.

## Accessibility
Terminal-only feature. Color is an **additive** signal: a valid abbreviation is green AND carries a textual `→ expansion` hint, so the meaning is not conveyed by color alone. Colors are Catppuccin Mocha palette values consistent with the rest of the theme; the dim hint uses `overlay0` which meets the theme's established contrast for secondary text. No interactive targets.

## Out of Scope
- Expanding/executing abbreviations (zsh-abbr already does this on space/enter).
- A configuration UI or user-facing options for colors (hardcode Catppuccin Mocha values; revisit only if requested).
- Recoloring/hinting inside command substitutions, here-docs, or quoted strings.
- Recognizing abbreviations defined by other tools (only zsh-abbr's four arrays).
- nix-darwin packaging — this is a stow package only; no `flake.nix` change.
- Multi-segment RPROMPT merging (showing the hint *and* oh-my-posh's node/python simultaneously). We replace, not merge.

## Rabbit Holes
- **Re-implementing F-Sy-H's tokenizer.** Don't. Use zsh's built-in `${(z)BUFFER}` lexer for command-position detection and a small separator list; that is sufficient for command-position vs argument. Full shell-grammar parsing is unnecessary.
- **Depending on antidote/zsh-defer queue ordering to get precedence.** Don't make correctness hinge on the relative position of a local `kind:defer` entry. Instead, do the precmd-guarded registration: gate on `(( $+functions[_zsh_highlight] ))` and self-remove. The defer-ordering approach is only the documented fallback.
- **Fighting oh-my-posh for RPROMPT ownership across prompts.** Don't try to hook oh-my-posh's precmd or merge segments. Instead, capture `$RPROMPT` lazily at hint activation and restore it on `zle-line-finish`, then let oh-my-posh's own precmd recompute normally on the next prompt.
- **Calling `zle reset-prompt` on every redraw.** Don't — it thrashes the prompt and feels laggy. Gate it behind the `_ZAH_LAST_HINT` change check (compare and skip when unchanged).
- **Wrapping `_zah_redraw` in `zle -N`.** Don't — `add-zle-hook-widget` takes a plain function name. Adding `zle -N` creates a redundant standalone widget and confuses the registration contract. Register the bare function name.
- **Chroma/theme override as the first approach for Part A.** Don't start there; it is the contingency. Implement the `region_highlight` append first and prove precedence; only switch to a chroma/`unknown-token` override if the zpty test shows append loses.

## No-Gos
- Do **not** register the `line-pre-redraw` hook before F-Sy-H is loaded. Because F-Sy-H is `kind:defer` (`zsh/.zsh_plugins.txt`: `zdharma-continuum/fast-syntax-highlighting kind:defer`), it loads after the first prompt via zsh-defer's FIFO queue; registration MUST be gated on `(( $+functions[_zsh_highlight] ))` so our hook lands after F-Sy-H wraps its widgets.
- Do **not** source the plugin's hook registration from `antidote.zsh` right after `antidote load` — F-Sy-H is not loaded at that point. Wire via `.zshrc` after the oh-my-posh block and register through the one-shot `precmd` guard.
- Do **not** wrap `_zah_redraw` / `_zah_restore_rprompt` in `zle -N`; pass the plain function name to `add-zle-hook-widget`.
- Do **not** edit `flake.lock` or `.zcompdump` — blocked by the PreToolUse hook (`.claude/settings.json`: "PreToolUse: Blocks edits to flake.lock and .zcompdump (generated files)").
- Do **not** add this as a Homebrew/nix package: per CLAUDE.md, "CLI tools via nix (`environment.systemPackages`), GUI apps with auto-updaters via Homebrew casks." This is neither; it is a stow package. "Each root-level directory is a **stow package** that mirrors home directory structure."
- The stow package tree MUST mirror the home directory: per CLAUDE.md, "Each root-level directory is a **stow package** that mirrors home directory structure" — the plugin file path under the package must resolve to a valid `~/...` target (`zsh-abbr-hint/.config/zsh/zsh-abbr-hint.plugin.zsh` → `~/.config/zsh/zsh-abbr-hint.plugin.zsh`).
- Keep any future nix entries alphabetically sorted: per CLAUDE.md, "Keep entries in `systemPackages`, `casks`, `brews`, and `taps` alphabetically sorted" (applies only if a nix change is ever added; this feature adds none).
- Theming MUST be Catppuccin Mocha: per CLAUDE.md, "Theme: Catppuccin Mocha across all tools." Use `#a6e3a1` (green) and `#6c7086` (overlay0) — both verified in `oh-my-posh/.config/oh-my-posh/config.toml` `[palette]`.
- Verify shell config changes in a fresh shell, not the current session, per CLAUDE.md Gotchas: "After any shell config change, verify in a fresh shell (`exec zsh` or new terminal) — not the current session."
- Every abbreviation lookup MUST quote the probe key with `${(qqq)word}` and unquote the stored value with `${(Q)...}` (matching `zsh-abbr.zsh` lines 279–312). A raw, unquoted key lookup will silently miss.
- Tokenize **command position only** for regular abbreviations: `echo gst` must NOT recolor `gst`. Respect separators `;` `|` `&&` `||` `&`.
- Do NOT call zsh-abbr's expansion to produce the preview — read the arrays directly. Expansion mutates the buffer.

## Tests
No CI exists in this repo; "tests pass" means runnable locally via `zsh zsh-abbr-hint/tests/run.zsh` from `~/dotfiles`. Only dependency beyond zsh is the built-in `zsh/zpty` module. F-Sy-H, zsh-abbr, and globalias are sourced from the antidote cache (or a pinned path) at:
- `~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr/zsh-abbr.plugin.zsh`
- `~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh`
- `~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/globalias/globalias.plugin.zsh`

`tests/lib.zsh` resolves these paths and skips with a clear message if absent.

**Tier 1 — Unit (`test_lookup.zsh`, no TTY).** Pure-function assertions on the lookup core. Seed the four `ABBR_*` arrays with `(qqq)`-quoted fixtures and assert:
- known regular key → is-abbr=1, correct unquoted expansion, scope `regular`;
- known global key → is-abbr=1, scope `global`;
- unknown key → is-abbr=0;
- `(qqq)` quoting: a key with a space (`"dotfiles pl"`) matches only via the quoted probe;
- command-position tokenizer: `gst` at line start → command position; `echo gst` → `gst` not command position; after `; ` / `| ` → command position.
This tier deterministically tests byte-stable string output and is the regression net.

**Tier 2 — Integration / precedence (`test_precedence.zsh`, zpty). This is the Part A gate and MUST run first.** The test MUST reproduce the **real deferred-load timing**, not a synthetic source order. Specifically, under `zpty`:
1. Source F-Sy-H the way zsh-defer would — i.e. source it (which runs `_zsh_highlight_bind_widgets`, wrapping the editing widgets and defining `_zsh_highlight`) BEFORE running our registration path, mimicking the post-first-prompt drain where F-Sy-H's deferred source completes first.
2. Then run our `_zah_register` path (which guards on `(( $+functions[_zsh_highlight] ))` and calls `add-zle-hook-widget line-pre-redraw _zah_redraw`), proving registration only proceeds once F-Sy-H is present.
3. Type a known abbreviation and assert both:
   - our green span is present in `region_highlight` over the command word, appended after F-Sy-H's red `unknown-token` span (later index = renders last); and
   - the rendered ANSI shows green (`#a6e3a1`) for that word, not F-Sy-H's red `unknown-token`.

A second sub-case asserts the **guard**: with `_zsh_highlight` NOT defined, `_zah_register` does not register the hook (proving we never install before F-Sy-H, the kind:defer failure mode). Because F-Sy-H wraps editing widgets (not `line-pre-redraw`, which it explicitly excludes), and ZLE runs `line-pre-redraw` hooks after the wrapped widget body has rebuilt `region_highlight`, this test proves our append wins under realistic ordering. Use a **wait-for-prompt drain loop** (poll `zpty -r` until the prompt/echo is observed) — no fixed `sleep`s (they were flaky). If this test fails, Part A stops and the contingency (chroma/`unknown-token` override) is implemented and re-tested here. No further Part A work proceeds until this passes.

**Tier 3 — Integration hint (`test_hint.zsh`, zpty).** With oh-my-posh's RPROMPT simulated by a fixture value, assert:
- typing a known abbreviation sets `RPROMPT` to the dim `→ expansion`;
- clearing the line restores the fixture RPROMPT;
- `zle reset-prompt` is not called when the hint is unchanged;
- **globalias case (load-bearing):** with globalias sourced and space bound to its widget, type a **global** abbreviation (recolored + hint shown), then press space to trigger globalias expansion (`zle _expand_alias; zle expand-word; zle self-insert`). Assert that after expansion (a) the hint is gone and `RPROMPT` is restored to the fixture value, and (b) no stale green span remains over the now-expanded text in `region_highlight`. This proves the expansion→redraw→re-evaluate ordering is safe.

**Tier 4 — Visual/manual (Part B, documented in README).** `tmux capture-pane -e` (or a screenshot) of a live shell to eyeball the dim hint placement against oh-my-posh's right segment. Not automated; a documented manual check.

## Open Questions
No open questions.
