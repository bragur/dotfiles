# Source Antidote
# Use the correct brew path (works with both nix-managed and standalone homebrew)
if [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /usr/local/opt/antidote/share/antidote/antidote.zsh
fi

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
if command -v antidote &> /dev/null; then
  antidote load
fi
