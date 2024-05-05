export ZSH_HOME="$HOME/.config/zsh"

ENABLE_CORRECTION="true"

# Settings for vi-mode
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true # Redraws prompt on mode change
VI_MODE_SET_CURSOR=true                  # Allows changing cursor mode
VI_MODE_CURSOR_INSERT=5                  # Use blinking cursor when in insert mode

# --- User configuration ---
export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"
eval "$(fzf --zsh)"
[[ ! -f $ZSH_HOME/exports.zsh ]] || source $ZSH_HOME/exports.zsh
[[ ! -f $ZSH_HOME/functions.zsh ]] || source $ZSH_HOME/functions.zsh
[[ ! -f $ZSH_HOME/switch_nvim.zsh ]] || source $ZSH_HOME/switch_nvim.zsh
[[ ! -f $ZSH_HOME/options.zsh ]] || source $ZSH_HOME/options.zsh
[[ ! -f $ZSH_HOME/mise.zsh ]] || source $ZSH_HOME/mise.zsh
[[ ! -f $ZSH_HOME/extra_plugins.zsh ]] || source $ZSH_HOME/extra_plugins.zsh
[[ ! -f $ZSH_HOME/expand_aliases.zsh ]] || source $ZSH_HOME/expand_aliases.zsh
[[ ! -f $ZSH_HOME/antidote.zsh ]] || source $ZSH_HOME/antidote.zsh
[[ ! -f $ZSH_HOME/aliases.zsh ]] || source $ZSH_HOME/aliases.zsh

# Starship prompt init
eval "$(starship init zsh)"
