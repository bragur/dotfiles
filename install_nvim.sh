#!/bin/bash
set -Eeuo pipefail

if [ "${1}" != "--source-only" ]; then
	. ./print.sh --source-only
fi

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

link_neovim() {
	info "Setting up neovim"
	info "Deleting existing config"
	rm -rf "$HOME/.config/nvim"
	info "Setting up symlinks"
	ln -s "$DOTFILES_ROOT/.dotfiles/nvim" "$HOME/.config/nvim"
	success "Neovim setup"
}

if [ "${1}" != "--source-only" ]; then
	link_neovim "${@}"
fi
