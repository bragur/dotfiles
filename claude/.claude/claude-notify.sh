#!/usr/bin/env bash
# Claude Code hook: forward attention events to Hammerspoon (see ~/.hammerspoon/claude.lua).
# Usage: claude-notify.sh <needs-input|finished|clear>   (hook JSON on stdin)
set -u
state=$1
input=$(cat)
pane=${TMUX_PANE:-}
[ -n "$pane" ] || exit 0

# A background agent or command reporting in re-enters the turn as a synthetic
# user message, so Stop fires once per report. Only the last one is the real
# finish: a launch leaves "agentId: <id>"/"background with ID: <id>" in its tool
# result and its completion arrives as "<task-id><id></task-id>", so ids launched
# in this turn with no matching completion mean work is still running.
pending_work() {
  local transcript
  transcript=$(jq -r '.transcript_path // empty' <<<"$input")
  [ -f "$transcript" ] || return 1
  [ "$(jq -rs '
      map(select(.isSidechain != true and .type != "queue-operation")) as $all
      | ([ $all | to_entries[]
           | select(.value.type == "user" and (.value.isMeta != true)
                    and (.value.message.content | type == "string")
                    and ((.value.message.content | test("<task-notification>")) | not))
           | .key ] | last // -1) as $turn
      | [ $all[($turn + 1):] | (.. | strings) ] as $text
      | ([ $text[] | scan("(?:agentId: |background with ID: )([a-z0-9]+)")[] ] | unique)
        - ([ $text[] | scan("<task-id>([a-z0-9]+)</task-id>")[] ] | unique)
      | length' "$transcript" 2>/dev/null)" != "0" ]
}

case $state in
  finished) pending_work && exit 0 ;;
  clear) jq -e '.prompt // "" | test("<task-notification>")' <<<"$input" >/dev/null && exit 0 ;;
esac

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
