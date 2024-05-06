local M = {}

M.treesitter = {
	ensure_installed = {
		"vim",
		"lua",
		"html",
		"css",
		"javascript",
		"typescript",
		"tsx",
		"markdown",
		"markdown_inline",
		"rescript",
	},
}

M.mason = {
	ensure_installed = {
		"lua-language-server",
		"rescript-language-server",
		"stylua",
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"prettier",
	},
}

M["which-key"] = {
	opts = function()
		require("utils").notify("YOO")
	end,
	window = {
		border = "double",
		position = "top",
	},
}

M.nvimtree = {
	git = {
		enable = true,
	},

	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = true,
			},
		},
	},
}

return M
