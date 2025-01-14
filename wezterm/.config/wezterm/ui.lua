local M = {}

function M.apply_to_config(config)
	config.color_scheme = "Catppuccin Mocha" -- scheme_for_appearance(wezterm.gui.get_appearance())
	config.window_padding = {
		left = 0,
		top = 0,
		right = 0,
		bottom = 0,
	}
	config.inactive_pane_hsb = {
		saturation = 0.8,
		brightness = 0.7,
	}
	config.scrollback_lines = 1000
	config.default_cursor_style = "BlinkingBar"
	config.cursor_blink_rate = 500
	config.window_background_opacity = 0.92
	config.macos_window_background_blur = 3
	config.window_decorations = "RESIZE"
	config.window_padding = {
		left = 8,
		top = 16,
		right = 8,
		bottom = 8,
	}
end

return M
