#!/bin/bash

tmux rename-window monorepo
tmux splitw -h -l '33%'
tmux splitw -l '33%'
tmux select-pane -t 1.1
tmux send-keys -t 1.2 "runweb 1.3" C-m
clear
nvim
