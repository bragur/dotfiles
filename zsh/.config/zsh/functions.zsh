tm() {
	if tmux has-session -t "$1" 2>/dev/null; then
		tmux attach -t "$1"
	else
		tmux new -s "$1"
	fi
}

runweb() {
	# Check if the correct number of arguments are provided
	if [[ -z "$1" ]]; then
		echo "Error: No tmux target specified."
		return 1
	fi

	yarn && yarn build && clear
	# Send the command to the specified pane
	tmux send-keys -t "$1" "yarn web:start" C-m

	yarn watch
}

runclean() {
	# Check if the correct number of arguments are provided
	if [[ -z "$1" ]]; then
		echo "Error: No tmux target specified."
		return 1
	fi

	yarn clean && yarn && yarn build && clear
	# Send the command to the specified pane
	tmux send-keys -t "$1" "yarn web:start" C-m

	yarn watch
}

cleanweb() {
	if [[ -z "$1" ]]; then
		echo "Error: No tmux target specified."
		return 1
	fi

	if ! tmux list-panes -t "$1" &>/dev/null; then
		echo "Error: Specified tmux pane does not exist."
		return 1
	fi

	yarn clean && yarn && yarn build && clear
	if [[ $? -ne 0 ]]; then
		echo "Build failed, stopping."
		return 1
	fi

	tmux send-keys -t "$1" "yarn web:start" C-m
	clear
	yarn watch
}

cx() {
  cd "$1" && ls
}

# Git helper functions (replaces ohmyzsh git plugin)
git_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
    if command git show-ref -q --verify "$ref"; then
      echo "${ref##*/}"
      return 0
    fi
  done
  echo master
  return 1
}

git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify "refs/heads/$branch"; then
      echo "$branch"
      return 0
    fi
  done
  echo develop
  return 1
}