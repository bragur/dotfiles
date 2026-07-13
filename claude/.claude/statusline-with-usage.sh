#!/usr/bin/env bash
#
# Claude Code statusLine wrapper.
#
# Claude Code allows only one statusLine command, but we want two things from
# the session JSON it pipes in on every render:
#   1. Render the visible Catppuccin status line (statusline-command.js).
#   2. Feed the same JSON to the tmux-claude-usage "harvester", which caches
#      account usage (rate_limits) for the `#{claude_usage}` tmux segment and
#      prints nothing.
#
# This wrapper reads stdin once and fans it out to both, printing only the
# rendered status line. Uses $HOME so it is portable across machines.

set -uo pipefail

HARVESTER="$HOME/.tmux/plugins/tmux-claude-usage/scripts/statusline.sh"
RENDER="$HOME/.claude/statusline-command.js"

input="$(cat)"

# Cache usage for the tmux segment (silent; never blocks the status line).
if [ -x "$HARVESTER" ]; then
	printf '%s' "$input" | "$HARVESTER" >/dev/null 2>&1 || true
fi

# Render the visible status line.
printf '%s' "$input" | node "$RENDER"
