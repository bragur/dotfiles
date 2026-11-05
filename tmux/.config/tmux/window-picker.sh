#!/usr/bin/env bash
# Fuzzy window picker. Tab switches between this session and all sessions.
# With an empty query, 1-9 jump straight to that row.

self=$(realpath "$0")
name='#{s|^[^a-zA-Z0-9]* ||:#{s|bragi-||:#{window_name}}}'
status='#{?@workmux_status,#{@workmux_status},  }'
on=$'\e[1;30;45m'
off=$'\e[0;2m'
reset=$'\e[0m'

list() {
  if [ "$1" = all ]; then
    tmux list-windows -a -F "#{session_name}:#{window_index}	$status  #{session_name}  $name"
  else
    tmux list-windows -t "$(tmux display -p '#S')" -F "#{session_name}:#{window_index}	$status  $name"
  fi | awk -F'\t' -v OFS='\t' '{print $1, NR "  " $2}'
}

header() {
  if [ "$1" = all ]; then
    echo "${off} This session ${reset} ${on} All sessions ${reset}"
  else
    echo "${on} This session ${reset} ${off} All sessions ${reset}"
  fi
}

case "$1" in
  list) list "$2"; exit ;;
  toggle)
    [ "$FZF_PROMPT" = '🪟  ' ] && next=all prompt='🌐  ' || next=session prompt='🪟  '
    echo "change-prompt($prompt)+change-header($(header "$next"))+reload($self list $next)+first"
    exit ;;
esac

digits=()
for i in 1 2 3 4 5 6 7 8 9; do
  digits+=(--bind "$i:transform:[ -n \"\$FZF_QUERY\" ] && echo 'put($i)' || echo 'pos($i)+accept'")
done

target=$(
  list session |
    fzf --ansi --delimiter '\t' --with-nth 2 --no-sort --reverse \
      --border-label ' windows ' --prompt '🪟  ' --header "$(header session)" \
      --bind "tab:transform:$self toggle" \
      "${digits[@]}" \
      --preview "tmux capture-pane -ep -t {1} | awk 'NF{for(;n>0;n--)print \"\";print;next}{n++}'" \
      --preview-window 'down,65%,follow' |
    cut -f1
)

[ -n "$target" ] && tmux switch-client -t "$target"
