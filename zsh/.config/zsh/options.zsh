# HISTORY
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=$HISTSIZE

# TERM OPTIONS
export EDITOR=nvim
TERM=tmux-256color
# TERM=wezterm

# OPTIONS
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks   # remove superfluous blanks from history items
setopt inc_append_history   # save history entries as soon as they are entered
setopt share_history        # share history between different instances of the shell
setopt auto_cd              # cd by typing directory name if it's not a command
setopt auto_list            # automatically list choices on ambiguous completion
setopt auto_menu            # automatically use menu completion
setopt always_to_end        # move cursor to end if word had one match

# IMPROVE AUTOCOMPLETION STYLE
zstyle ':completion:*' menu select                                          # select completions with arrow keys
zstyle ':completion:*' group-name ''                                        # group results by category
zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'                         # matches case insensitive for lowercase
zstyle ':completion:*' insert-tab pending                                   # pasting with tabs doesn't perform completion
