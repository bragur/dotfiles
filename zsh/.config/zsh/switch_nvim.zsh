check_neovim_running() {
	# Check if the NVIM environment variable is set, indicating this is running within a Neovim terminal.
	if [[ -n $NVIM ]]; then
		print "Running NVIM terminal"
		return 1 # Returning 0 for this case to simply exit this check function.
	fi

	# Use pgrep to check for running nvim processes. Adjust if your Neovim is launched with a different command.
	if pgrep -x nvim >/dev/null; then
		print "Running another instance"
		return 1
	fi

	return 0
}

switch_nvim_distro_cli() {
	if ! check_neovim_running; then
		print -P "%F{red}Neovim is running. Please close all instances before switching distros.%f"
		return 1
	else
		print "Available Neovim configurations:"
		local configs=("$HOME/.config/nvim-distros"/*)
		local i=1
		for config in "${configs[@]}"; do
			print -P "%F{yellow}${i}:%f %F{cyan}$(basename "$config")%f"
			((i++))
		done

		print -P "%F{yellow}Select a distro:%f"
		read -r selection

		local selected_config_name="$(basename "${configs[$selection]}")"
		print "${selected_config_name}"

		if [[ -z "$selected_config_name" ]]; then
			print -P "%F{red}Invalid selection%f"
			return 1
		fi

		echo "export NVIM_APPNAME=\"nvim-distros/$selected_config_name\"" >"$ZSH_HOME/nvim_appname.zsh"
	fi
}
