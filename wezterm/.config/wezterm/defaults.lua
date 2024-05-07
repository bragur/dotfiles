local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

function M.apply_to_config(config)
	config.automatically_reload_config = true
	config.hide_tab_bar_if_only_one_tab = true
	-- Swap Option keys -> AltGr https://wezfurlong.org/wezterm/config/keyboard-concepts.html?h=macos#macos-left-and-right-option-key
	config.send_composed_key_when_left_alt_is_pressed = true
	config.send_composed_key_when_right_alt_is_pressed = false

	config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 2000 }
	config.keys = {
		{ key = "s", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "h", mods = "CMD", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "f", mods = "LEADER", action = act.ToggleFullScreen },
		{ key = "-", mods = "CTRL", action = "DisableDefaultAssignment" },
		{ key = "+", mods = "CTRL", action = "DisableDefaultAssignment" },
		{ key = "-", mods = "CMD", action = "DecreaseFontSize" },
		{ key = "+", mods = "CMD", action = "IncreaseFontSize" },
	}
end

return M
