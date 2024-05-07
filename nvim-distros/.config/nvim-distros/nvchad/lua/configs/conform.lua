local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		html = { "prettier" },
		css = { "prettier" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		rescript = { "rescript-format" },
		json = { "fixjson" },
		markdown = { "markdownlint" },
	},
	format_on_save = {
		lsp_fallback = true,
		timeout_ms = 500,
	},
	notify_on_error = true,
	lsp_fallback = true,
}

require("conform").setup(options)
