local wezterm = require("wezterm")
local M = {}

function M.apply_to_config(config)
	config.font = wezterm.font({
		family = "Maple Mono NF",
		harfbuzz_features = {
			"cv01",
			"cv02",
			"cv03",
			"cv04",
			"ss01",
			"ss02",
			"ss04",
			"ss05",
		},
	})
	config.font_size = 11.0
	config.line_height = 1.35
end

return M
