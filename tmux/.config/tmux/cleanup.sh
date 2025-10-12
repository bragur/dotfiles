#!/bin/bash

if [ -n "$1" ]; then
	main_session="$1"
	popup_session="${main_session}-popup"

	tmux list-windows -t "$main_session" -F "#{window_id} #{window_name} #{window_layout}" >"$HOME/.tmux/${main_session}_windows.txt"

	if tmux has-session -t "$popup_session" 2>/dev/null; then
		tmux kill-session -t "$popup_session"
	fi
fi
