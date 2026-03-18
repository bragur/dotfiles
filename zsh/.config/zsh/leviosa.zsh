# Leviosa worktree shortcuts
LEVIOSA_DIR=~/Developer/leviosa-app

# General
alias lfs="npm run start:fe"
alias lbs="npm run start:be"
alias lbsf="npm run start:be:fresh"
alias lseed="npm run seed"

# Worktrees
WT=$LEVIOSA_DIR/scripts/worktree.sh
alias wtl="$WT list"
alias wts="$WT snapshot"
alias wtd="python3 $LEVIOSA_DIR/scripts/worktree-dashboard"
wtc()  { $WT create "$@"; }
wtcf() { $WT create "$1" --fe-only; }
wtcd() { $WT create "$1" --with-db; }
wtr()  { $WT remove "$@"; }
wtcd() { cd $LEVIOSA_DIR/.worktrees/$1; }