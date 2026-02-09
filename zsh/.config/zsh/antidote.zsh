# Source Antidote plugin manager
# Nix-darwin path (primary), Homebrew paths (fallback)
if [[ -f /run/current-system/sw/share/antidote/antidote.zsh ]]; then
  source /run/current-system/sw/share/antidote/antidote.zsh
elif [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /usr/local/opt/antidote/share/antidote/antidote.zsh
fi

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
if command -v antidote &> /dev/null; then
  antidote load
fi
