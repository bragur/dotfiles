export ZSH_HOME="$HOME/.config/zsh"
ENABLE_CORRECTION="true"

# Raise file descriptor limit (macOS default of 256 is too low for Claude Code + tmux)
ulimit -n 10240

# --- User configuration ---
[[ ! -f $ZSH_HOME/exports.zsh ]] || source $ZSH_HOME/exports.zsh
[[ ! -f $ZSH_HOME/functions.zsh ]] || source $ZSH_HOME/functions.zsh
[[ ! -f $ZSH_HOME/options.zsh ]] || source $ZSH_HOME/options.zsh
[[ ! -f $ZSH_HOME/antidote.zsh ]] || source $ZSH_HOME/antidote.zsh
[[ ! -f $ZSH_HOME/aliases.zsh ]] || source $ZSH_HOME/aliases.zsh

# autoload -Uz promptinit && promptinit
# Cache compinit for faster startup (rebuilds once per day)
# Skip security checks (-u) for speed
autoload -Uz compinit
setopt EXTENDEDGLOB
for dump in ~/.zcompdump(N.mh+24); do
  compinit -u
done
if [[ -s ~/.zcompdump && (! -s ~/.zcompdump.zwc || ~/.zcompdump -nt ~/.zcompdump.zwc) ]]; then
  zcompile ~/.zcompdump
fi
compinit -C -u

export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"
eval "$(mise activate zsh)"
eval "$(fzf --zsh)"
eval "$(atuin init zsh)"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
	# Cache oh-my-posh init for slightly faster startup
	eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
	# Enable transient prompt for snappier feel
	enable_poshtooltips
fi

export CARAPACE_BRIDGES='zsh'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

export PATH="$HOME/.local/bin:$PATH"

eval "$(zoxide init zsh)"

[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

# Warm QMD embedding model on shell startup (detached, silent)
[ -x /Users/bragur/Developer/memento-vault/bin/memento-vault ] && /Users/bragur/Developer/memento-vault/bin/memento-vault warmup >/dev/null 2>&1
