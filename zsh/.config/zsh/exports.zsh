export PROJECT_DIR="$HOME/Developer"
mkdir -p "$PROJECT_DIR"

# Keep PATH free of duplicates when nested shells re-source this file
typeset -U path PATH

# zsh-abbr: enable cursor positioning in expansions (must be set before antidote loads zsh-abbr)
ABBR_SET_EXPANSION_CURSOR=1
ABBR_EXPANSION_CURSOR_MARKER='%'

# Binaries from `go install` (golangci-lint etc.)
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Zulu JDK 17 for React Native Android builds (Homebrew cask zulu@17).
# Guarded: a machine without the cask should not get a broken JAVA_HOME.
_zulu17_home=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
[[ ! -d $_zulu17_home ]] || export JAVA_HOME=$_zulu17_home
unset _zulu17_home

# Android SDK for React Native / Expo (Android Studio's default SDK location).
if [[ -d $HOME/Library/Android/sdk ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
  path=($ANDROID_HOME/platform-tools $ANDROID_HOME/emulator $path)
fi
