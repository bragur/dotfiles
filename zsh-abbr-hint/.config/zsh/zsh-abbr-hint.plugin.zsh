# zsh-abbr-hint.plugin.zsh
#
# A ZLE plugin that:
#   Part A — appends a green region_highlight span over a command-position
#            abbreviation word, overriding fast-syntax-highlighting's red
#            unknown-token colour.
#   Part B — sets RPROMPT to a dim "→ expansion" hint while editing a known
#            abbreviation, and restores oh-my-posh's RPROMPT on accept/clear.
#
# Stow target: ~/.config/zsh/zsh-abbr-hint.plugin.zsh
# Wire from ~/.zshrc after the oh-my-posh init block:
#   [[ ! -f $ZSH_HOME/zsh-abbr-hint.plugin.zsh ]] || source $ZSH_HOME/zsh-abbr-hint.plugin.zsh
#
# Depends on:
#   - olets/zsh-abbr        (kind:defer via antidote)
#   - zdharma-continuum/fast-syntax-highlighting (kind:defer via antidote)
#   - oh-my-posh            (eval'd in .zshrc after antidote)
#
# All public names are prefixed _zah_ to avoid polluting the global namespace.

# ---------------------------------------------------------------------------
# Plugin-global runtime state
# ---------------------------------------------------------------------------
autoload -Uz add-zsh-hook

typeset -g  _ZAH_RPROMPT_SAVED=""   # last-seen oh-my-posh RPROMPT (lazy capture)
typeset -g  _ZAH_LAST_HINT=""       # last hint rendered; change-gate for reset-prompt
typeset -gi _ZAH_HINT_ACTIVE=0      # 1 while our hint owns RPROMPT

# ---------------------------------------------------------------------------
# _zah_lookup <word>
#   Returns 0 if <word> is a known zsh-abbr abbreviation, 1 otherwise.
#   On success, sets:
#     REPLY  — the unquoted expansion string
#     REPLY2 — scope: "regular" or "global"
# ---------------------------------------------------------------------------
_zah_lookup() {
  local word=${1:-}
  local key="${(qqq)word}"
  REPLY=""
  REPLY2=""

  # Regular session abbreviations
  if (( ${+ABBR_REGULAR_SESSION_ABBREVIATIONS} )) && \
     [[ -n "${ABBR_REGULAR_SESSION_ABBREVIATIONS[$key]+set}" ]]; then
    REPLY="${(Q)ABBR_REGULAR_SESSION_ABBREVIATIONS[$key]}"
    REPLY2="regular"
    return 0
  fi

  # Regular user abbreviations
  if (( ${+ABBR_REGULAR_USER_ABBREVIATIONS} )) && \
     [[ -n "${ABBR_REGULAR_USER_ABBREVIATIONS[$key]+set}" ]]; then
    REPLY="${(Q)ABBR_REGULAR_USER_ABBREVIATIONS[$key]}"
    REPLY2="regular"
    return 0
  fi

  # Global session abbreviations
  if (( ${+ABBR_GLOBAL_SESSION_ABBREVIATIONS} )) && \
     [[ -n "${ABBR_GLOBAL_SESSION_ABBREVIATIONS[$key]+set}" ]]; then
    REPLY="${(Q)ABBR_GLOBAL_SESSION_ABBREVIATIONS[$key]}"
    REPLY2="global"
    return 0
  fi

  # Global user abbreviations
  if (( ${+ABBR_GLOBAL_USER_ABBREVIATIONS} )) && \
     [[ -n "${ABBR_GLOBAL_USER_ABBREVIATIONS[$key]+set}" ]]; then
    REPLY="${(Q)ABBR_GLOBAL_USER_ABBREVIATIONS[$key]}"
    REPLY2="global"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# _zah_command_word
#   Examines $BUFFER up to $CURSOR and determines whether the word at the
#   cursor is in command position.
#   Sets:
#     REPLY  — the word at (or just before) the cursor
#     REPLY2 — "1" if cursor word is in command position, "0" otherwise
# ---------------------------------------------------------------------------
_zah_command_word() {
  REPLY=""
  REPLY2="0"

  local buf="${BUFFER[1,$CURSOR]}"
  [[ -z $buf ]] && return

  # Tokenize with zsh's lexer
  local -a tokens
  tokens=( ${(z)buf} )
  [[ ${#tokens} -eq 0 ]] && return

  local word="${tokens[-1]}"
  REPLY="$word"

  # Separators that reset command position
  local -a separators
  separators=( ';' '|' '&&' '||' '&' $'\n' '(' )

  if [[ ${#tokens} -eq 1 ]]; then
    # First and only word — command position
    REPLY2="1"
    return
  fi

  # Check if the previous token is a separator
  local prev="${tokens[-2]}"
  local sep
  for sep in "${separators[@]}"; do
    if [[ "$prev" == "$sep" ]]; then
      REPLY2="1"
      return
    fi
  done

  REPLY2="0"
}

# ---------------------------------------------------------------------------
# _zah_redraw
#   line-pre-redraw ZLE hook. Runs Part A (region_highlight green span) and
#   Part B (RPROMPT hint) logic on every redraw.
# ---------------------------------------------------------------------------
_zah_redraw() {
  # --- Part A & B: determine if an abbreviation is active ---
  local cmd_word cmd_pos
  _zah_command_word
  cmd_word="$REPLY"
  cmd_pos="$REPLY2"

  local is_abbr=0 expansion="" scope=""
  if [[ -n "$cmd_word" ]] && _zah_lookup "$cmd_word"; then
    expansion="$REPLY"
    scope="$REPLY2"
    # Regular abbreviations: command position only
    # Global abbreviations: anywhere
    if [[ "$scope" == "global" || "$cmd_pos" == "1" ]]; then
      is_abbr=1
    fi
  fi

  # --- Part A: green region_highlight span ---
  if (( is_abbr )); then
    # Find byte offsets of cmd_word in $BUFFER
    # We look for the word starting from the last separator or start of buffer
    local buf_pre="${BUFFER[1,$CURSOR]}"
    local word_start word_end
    # Find the position of the word in the buffer
    local word_pos=$(( ${buf_pre[(I)$cmd_word]} - 1 ))
    word_start="$word_pos"
    word_end=$(( word_start + ${#cmd_word} ))
    region_highlight+=("$word_start $word_end fg=#a6e3a1,bold")
  fi

  # --- Part B: RPROMPT hint ---
  if (( is_abbr )); then
    local hint="→ ${expansion}"
    if [[ "$hint" != "$_ZAH_LAST_HINT" ]]; then
      # Lazy capture of oh-my-posh's RPROMPT on first activation
      if (( ! _ZAH_HINT_ACTIVE )); then
        _ZAH_RPROMPT_SAVED="$RPROMPT"
        _ZAH_HINT_ACTIVE=1
      fi
      RPROMPT="%F{#6c7086}${hint}%f"
      _ZAH_LAST_HINT="$hint"
      zle reset-prompt
    fi
  else
    if (( _ZAH_HINT_ACTIVE )) || [[ -n "$_ZAH_LAST_HINT" ]]; then
      RPROMPT="$_ZAH_RPROMPT_SAVED"
      _ZAH_HINT_ACTIVE=0
      _ZAH_LAST_HINT=""
      zle reset-prompt
    fi
  fi
}

# ---------------------------------------------------------------------------
# _zah_restore_rprompt
#   zle-line-finish hook. Restores oh-my-posh's RPROMPT when the line is
#   accepted or aborted.
# ---------------------------------------------------------------------------
_zah_restore_rprompt() {
  if (( _ZAH_HINT_ACTIVE )); then
    RPROMPT="$_ZAH_RPROMPT_SAVED"
    _ZAH_HINT_ACTIVE=0
    _ZAH_LAST_HINT=""
  fi
}

# ---------------------------------------------------------------------------
# _zah_register
#   One-shot precmd hook. Guards on F-Sy-H being loaded (it defines
#   _zsh_highlight after its deferred source runs). Once the guard passes,
#   registers the ZLE hooks and self-removes.
# ---------------------------------------------------------------------------
_zah_register() {
  # F-Sy-H not yet loaded — wait for next precmd
  (( $+functions[_zsh_highlight] ))    || return 0
  (( $+functions[add-zle-hook-widget] )) || return 0

  add-zle-hook-widget line-pre-redraw _zah_redraw          # plain function hook
  add-zle-hook-widget zle-line-finish  _zah_restore_rprompt # plain function hook

  # Self-remove — one-shot.
  add-zsh-hook -d precmd _zah_register
}

# Install the one-shot precmd. add-zsh-hook is autoloaded above so it is
# available here at source time.
add-zsh-hook precmd _zah_register
