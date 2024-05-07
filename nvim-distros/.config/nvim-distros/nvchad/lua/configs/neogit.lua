return {
  lazy = true,
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = true,
	keys = {
		{ "<leader>gs", ":Neogit kind=auto<cr>", desc = "Neogit" },
		{ "<leader>gc", ":Neogit commit", desc = "Neogit commit" },
	},
}
