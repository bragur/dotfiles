export ZSH_HOME="$HOME/.config/zsh"
ENABLE_CORRECTION="true"

# Settings for vi-mode
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true # Redraws prompt on mode change
VI_MODE_SET_CURSOR=true                  # Allows changing cursor mode
VI_MODE_CURSOR_INSERT=5                  # Use blinking cursor when in insert mode

# --- User configuration ---
[[ ! -f $ZSH_HOME/exports.zsh ]] || source $ZSH_HOME/exports.zsh
[[ ! -f $ZSH_HOME/functions.zsh ]] || source $ZSH_HOME/functions.zsh
[[ ! -f $ZSH_HOME/switch_nvim.zsh ]] || source $ZSH_HOME/switch_nvim.zsh
[[ ! -f $ZSH_HOME/options.zsh ]] || source $ZSH_HOME/options.zsh
[[ ! -f $ZSH_HOME/mise.zsh ]] || source $ZSH_HOME/mise.zsh
[[ ! -f $ZSH_HOME/antidote.zsh ]] || source $ZSH_HOME/antidote.zsh
[[ ! -f $ZSH_HOME/aliases.zsh ]] || source $ZSH_HOME/aliases.zsh

# autoload -Uz promptinit && promptinit
autoload -Uz compinit && compinit

export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(~/.local/bin/mise activate zsh)"
eval "$(fzf --zsh)"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
	eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
fi
