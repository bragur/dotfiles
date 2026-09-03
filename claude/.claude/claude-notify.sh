#!/usr/bin/env bash
# Claude Code hook: forward attention events to Hammerspoon (see ~/.hammerspoon/claude.lua).
# Usage: claude-notify.sh <needs-input|finished|clear>   (hook JSON on stdin)
set -u
state=$1
input=$(cat)
pane=${TMUX_PANE:-}
[ -n "$pane" ] || exit 0

session=$(tmux display -pt "$pane" '#{session_name}' 2>/dev/null) || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input")
project=${cwd##*/}
message=$(jq -r '.message // .notification_type // empty' <<<"$input" | head -c 120)
event=$(jq -r '.notification_type // empty' <<<"$input")

query=$(jq -rn --arg state "$state" --arg pane "$pane" --arg session "$session" \
  --arg project "$project" --arg message "$message" --arg event "$event" \
  '[$state, $pane, $session, $project, $message, $event] as [$s, $p, $se, $pr, $m, $e]
   | "state=\($s|@uri)&pane=\($p|@uri)&session=\($se|@uri)&project=\($pr|@uri)&message=\($m|@uri)&event=\($e|@uri)"')

open -g "hammerspoon://claude?$query"
