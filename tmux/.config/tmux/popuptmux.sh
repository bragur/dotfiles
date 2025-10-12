#!/bin/bash

current_session_name=$(tmux display-message -p -F "#{session_name}")

if [[ "$current_session_name" == *"-popup" ]]; then
	tmux set-option -t "$current_session_name" status on
	tmux detach-client
else
	scratch_pad_name="${current_session_name}-popup"
	tmux new-session -d -s "$scratch_pad_name"
	tmux set-option -t "$scratch_pad_name" status off
	tmux set-option -t "$scratch_pad_name" popup-style none
	tmux set-option -t "$scratch_pad_name" popup-border-lines double
	tmux popup -w 200 -h 80% -T "$scratch_pad_name" -E "tmux attach -t $scratch_pad_name"
fi
