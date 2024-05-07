function expand-alias() {
	zle _expand_alias
	zle self-insert
}
zle -N expand-alias
bindkey -M main ' ' expand-alias

function expand-alias-and-execute() {
	zle _expand_alias
	zle accept-line
}

zle -N expand-alias-and-execute
bindkey "^M" expand-alias-and-execute
