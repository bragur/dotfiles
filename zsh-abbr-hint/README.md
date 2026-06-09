# zsh-abbr-hint

A ZLE plugin that provides live visual feedback while typing zsh-abbr abbreviations:

- **Green recolor** — a valid zsh-abbr abbreviation in command position renders in Catppuccin Mocha green (`#a6e3a1`, bold), overriding fast-syntax-highlighting's red `unknown-token` color. Invalid tokens stay red — the green signal is reserved for real abbreviations.
- **Dim expansion hint** — a dim `→ expansion` hint appears in RPROMPT while editing a known abbreviation, using Catppuccin Mocha overlay0 (`#6c7086`). oh-my-posh's right segment is restored the moment the abbreviation leaves the cursor or the line is accepted.

The feature is staged: **Part A** (green recolor) and **Part B** (RPROMPT hint) are both implemented in a single plugin file. Part A is gated on a zpty precedence test that proves the green `region_highlight` span wins over F-Sy-H's red span under realistic deferred-load timing before Part A proceeds.

## How it works

### Append-after-F-Sy-H precedence theory

fast-syntax-highlighting (F-Sy-H) wraps every editing ZLE widget via `_zsh_highlight_bind_widgets`. Each keypress fires the wrapped widget, which calls `_zsh_highlight`, resetting `region_highlight=()` and repopulating it — marking `gst` as a red `unknown-token`. Crucially, F-Sy-H explicitly excludes `zle-line-pre-redraw` from the widgets it wraps.

Per-keystroke timeline: keypress → F-Sy-H-wrapped widget → `_zsh_highlight` resets and repopulates `region_highlight` → ZLE runs the `line-pre-redraw` hook chain → our hook appends a green span at a later array index → terminal renders last-wins, so green wins over red.

### The `kind:defer` problem

In `zsh/.zsh_plugins.txt`, F-Sy-H is loaded `kind:defer`. antidote translates this into a `zsh-defer source <plugin>` call. zsh-defer maintains a single FIFO queue that drains asynchronously after the first prompt — so F-Sy-H's widget wrapping does **not** happen during `antidote load`. Sourcing our plugin immediately after `antidote load` would register our `line-pre-redraw` hook before F-Sy-H wraps its widgets, defeating the precedence theory.

### Deferred registration via `_zah_register` precmd guard (primary strategy)

We install a self-removing `precmd` hook that gates on `(( $+functions[_zsh_highlight] ))`:

```zsh
autoload -Uz add-zsh-hook
_zah_register() {
  (( $+functions[_zsh_highlight] ))      || return 0   # F-Sy-H not yet loaded; retry next precmd
  (( $+functions[add-zle-hook-widget] )) || return 0
  add-zle-hook-widget line-pre-redraw _zah_redraw
  add-zle-hook-widget zle-line-finish  _zah_restore_rprompt
  add-zsh-hook -d precmd _zah_register                  # one-shot: self-remove after success
}
add-zsh-hook precmd _zah_register
```

By the time `_zah_register` fires on the second prompt (after zsh-defer has drained its queue), `_zsh_highlight` is defined. The guard no-ops safely on every precmd until F-Sy-H is present, then registers once and removes itself. Zero steady-state cost.

`_zah_redraw` and `_zah_restore_rprompt` are registered as **plain function names** — `add-zle-hook-widget` does not require `zle -N`.

## Install

```zsh
cd ~/dotfiles
stow zsh-abbr-hint
```

This symlinks `zsh-abbr-hint/.config/zsh/zsh-abbr-hint.plugin.zsh` to `~/.config/zsh/zsh-abbr-hint.plugin.zsh`.

Add the following line to `zsh/.zshrc` **after** the oh-my-posh init block:

```zsh
# zsh-abbr-hint: defines functions + installs a one-shot precmd that registers
# its line-pre-redraw hook AFTER fast-syntax-highlighting (kind:defer) has loaded.
[[ ! -f $ZSH_HOME/zsh-abbr-hint.plugin.zsh ]] || source $ZSH_HOME/zsh-abbr-hint.plugin.zsh
```

`$ZSH_HOME` is defined on `.zshrc` line 1 (`export ZSH_HOME="$HOME/.config/zsh"`). Sourcing after the oh-my-posh block means oh-my-posh's precmd is already installed, making Part B's lazy `RPROMPT` capture straightforward.

After editing `.zshrc`, verify the plugin loaded in a **fresh shell** (`exec zsh` or open a new terminal tab) — not the current session:

```zsh
exec zsh
type _zah_lookup   # should print: _zah_lookup is a shell function
```

## Tests

Run all test tiers from `~/dotfiles`:

```zsh
zsh zsh-abbr-hint/tests/run.zsh
```

### Test files

| File | Tier | What it covers |
|---|---|---|
| `tests/test_lookup.zsh` | Tier 1 — Unit (no TTY) | `_zah_lookup` and `_zah_command_word` pure-function assertions: known regular/global keys, unknown key, `(qqq)`-quoted space-containing key, command-position tokenizer (first word, after `;`, after `|`, argument position) |
| `tests/test_precedence.zsh` | Tier 2 — Integration (zpty) | Part A gate: green span appended after F-Sy-H's red span (last-wins); guard sub-case proves `_zah_register` no-ops when `_zsh_highlight` is absent |
| `tests/test_hint.zsh` | Tier 3 — Integration (zpty) | Part B: RPROMPT hint activation, change-gate (`zle reset-prompt` not called when hint is unchanged), restore on clear; globalias expansion case (global abbreviation + space triggers expansion, hint clears, no stale green) |

### Antidote cache dependency

Tier 2 and Tier 3 source F-Sy-H, zsh-abbr, and globalias from the antidote cache:

```
~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr/zsh-abbr.plugin.zsh
~/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/globalias/globalias.plugin.zsh
```

When a cache path is absent the test **SKIPs cleanly** with a descriptive message — it does not fail. Tier 1 has no such dependency and always runs.

## Manual visual check (Tier 4)

Tier 4 is a manual eyeball test — not automated. To verify the dim hint placement against oh-my-posh's right segment:

1. Open a tmux session with the plugin active (fresh shell after `stow` + `.zshrc` wiring).
2. Start typing a known abbreviation such as `gst` — do **not** press Enter.
3. Capture the rendered pane output, preserving ANSI escape sequences:

```zsh
tmux capture-pane -e -p
```

**What to look for:**

- The `gst` word should render in Catppuccin Mocha green (`#a6e3a1`, truecolor ANSI `38;2;166;227;161`), not F-Sy-H's red.
- The right side of the line should show a dim `→ git status` in overlay0 (`#6c7086`), replacing oh-my-posh's node/python segment for the duration of editing.
- Pressing Enter (accept) or Ctrl-C (abort) should restore oh-my-posh's original RPROMPT on the next prompt line.
- Typing `echo gst` (argument position) should show no green recolor and no hint.

Alternatively, use a screenshot: in Ghostty, `Cmd+Shift+4` to capture a region; look for the green word and the dim right-side hint on the same line.

## Alternatives and fallbacks

### Registration fallback: local `kind:defer` entry

If the `precmd` guard approach ever proves flaky, an alternative is to add `zsh-abbr-hint` to `zsh/.zsh_plugins.txt` as a local `kind:defer` entry **after** the fast-syntax-highlighting line. zsh-defer's FIFO queue preserves relative order, so this would also ensure registration happens after F-Sy-H loads. This approach is not the primary because it couples correctness to antidote's translation of a local path entry and is less explicit than the `(( $+functions[_zsh_highlight] ))` guard. It is the documented fallback only.

### Precedence contingency: chroma/`unknown-token` override

If `region_highlight` append-after-F-Sy-H does not win at render time (i.e., the Tier 2 zpty test shows green losing to red), the fallback is to override F-Sy-H's `unknown-token` styling for known abbreviations via a small F-Sy-H chroma/`fast-theme` rule keyed on `_zah_lookup`, or a post-pass that rewrites F-Sy-H's `unknown-token` span style in place. The overlay-append strategy is the primary design; this contingency is only taken if Tier 2 proves append loses.
