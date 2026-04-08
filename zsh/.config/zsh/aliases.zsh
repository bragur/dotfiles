alias ls="eza --icons"
alias ll="eza --icons -alh"
alias tree="eza --tree"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

[[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr/leviosa-session-abbreviations ]] || zsh-defer source ${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr/leviosa-session-abbreviations