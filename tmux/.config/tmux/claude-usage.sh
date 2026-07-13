#!/usr/bin/env bash
#
# Compact Claude usage segment for tmux.
#
# Renders a tighter line than the plugin's own segment.sh — e.g. "░░░░░ 3% ⚡2h8m"
# instead of "░░░░░░░░░░ 3% used · resets in 2 hr 8 min": half-width bar, no
# "used", and a lightning + short reset. We keep tmux-claude-usage for its
# statusLine harvester (which caches the data) but render here so this format
# survives plugin updates and TPM's `prefix + U`.
#
# Reuses the plugin's helpers.sh for the bar rendering and @claude_usage_* option
# reads. Colour/pill styling is applied by the Catppuccin module in .tmux.conf,
# so this prints plain text.

set -uo pipefail

HELPERS="$HOME/.tmux/plugins/tmux-claude-usage/scripts/helpers.sh"
[ -r "$HELPERS" ] || exit 0
# shellcheck source=/dev/null
source "$HELPERS"

CACHE_FILE="$(usage_cache_file)"
[ -f "$CACHE_FILE" ] || exit 0

five_pct="" five_reset=""
while IFS='=' read -r key val; do
	case "$key" in
	FIVE_HOUR_PCT) five_pct="$val" ;;
	FIVE_HOUR_RESET) five_reset="$val" ;;
	esac
done <"$CACHE_FILE"

[ -n "$five_pct" ] || exit 0
printf -v pct '%.0f' "$five_pct" 2>/dev/null || exit 0

now="$(date +%s)"
have_reset=0
[[ "$five_reset" =~ ^[0-9]+$ ]] && have_reset=1

# Once the window's reset time has passed it has rolled over: usage is back to 0%
# and there's nothing to count down to (mirrors the plugin's self-expiring cache).
if [ "$have_reset" = 1 ] && [ "$now" -ge "$five_reset" ]; then
	pct=0
	have_reset=0
fi

bar_width="$(get_tmux_option @claude_usage_bar_width 5)"

# Compact reset: "2h8m", "3d2h", "45m".
compact_reset() {
	local s="$1" d h m
	((s < 0)) && s=0
	d=$((s / 86400))
	h=$(((s % 86400) / 3600))
	m=$(((s % 3600) / 60))
	if ((d > 0)); then
		printf '%dd%dh' "$d" "$h"
	elif ((h > 0)); then
		printf '%dh%dm' "$h" "$m"
	else
		printf '%dm' "$m"
	fi
}

parts=()
[ "$(get_tmux_option @claude_usage_show_bar on)" = on ] &&
	parts+=("$(render_bar "$pct" "$bar_width" \
		"$(get_tmux_option @claude_usage_bar_full '█')" \
		"$(get_tmux_option @claude_usage_bar_empty '░')")")
parts+=("${pct}%")
[ "$have_reset" = 1 ] && parts+=("⚡$(compact_reset $((five_reset - now)))")

# Plain text only — the Catppuccin module (.tmux.conf) supplies the pill colours,
# so emitting our own #[fg]/#[default] here would fight the segment background.
printf '%s' "${parts[*]}"
