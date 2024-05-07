local wezterm = require("wezterm")
local M = {}

function M.apply_to_config(config)
	-- config.font = wezterm.font({ family = "FiraCode Nerd Font Mono" })
	-- config.font = wezterm.font({ family = "BlexMono Nerd Font Mono" })
	config.font = wezterm.font({ family = "Hack Nerd Font" })
	config.font_size = 11.0
	config.line_height = 1.4
end

return M
