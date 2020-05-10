#!/bin/bash

success() {
	# shellcheck disable=SC2059
	printf "\r\033[2K  [\033[00;32mOK\033[0m] $1\n"
}

info() {
	# shellcheck disable=SC2059
	printf "\r  [\033[00;34m..\033[0m] $1\n"
}
