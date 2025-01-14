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
