return {
	version = "*",
	config = function()
		require("mini.move").setup({
			mappings = {
				down = "∆",-- "∆",
				up = "¬",
				left = "|",
				right = "…",
				line_down = "∆",
				line_up = "¬",
				line_left = "|",
				line_right = "…",
			},
		})
	end,
}
