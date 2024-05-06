return {
	version = "*",
	config = true,
	keys = {
		{ "<leader>sa", "<cmd>:FocusAutoResize<cr>", desc = "Auto Resize" },
		{ "<leader>se", "<cmd>:FocusMaxOrEqual<cr>", desc = "Toggle Maximize/Equal" },
		{ "<leader>sp", "<cmd>:FocusSplitNicely<cr>", desc = "Split Nicely" },
		{ "<leader>sh", "<cmd>:FocusSplitDown<cr>", desc = "Horizontal Split" },
		{ "<leader>sv", "<cmd>:FocusSplitRight<cr>", desc = "Vertical Split" },
		{ "<leader>sx", "<cmd>:FocusToggle<cr>", desc = "Toggle Focus" },
	},
}
