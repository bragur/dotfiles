alias ls="eza --icons"
alias ll="eza --icons -alh"
alias tree="eza --tree"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Machine-local abbreviations, untracked (session-scope `abbr -S -f` entries;
# deferred so zsh-abbr has loaded first)
[[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr/local-abbreviations ]] || zsh-defer source ${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr/local-abbreviations