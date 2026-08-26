export PROJECT_DIR="$HOME/Developer"
mkdir -p "$PROJECT_DIR"

# zsh-abbr: enable cursor positioning in expansions (must be set before antidote loads zsh-abbr)
ABBR_SET_EXPANSION_CURSOR=1
ABBR_EXPANSION_CURSOR_MARKER='%'

# Binaries from `go install` (golangci-lint etc.)
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"
