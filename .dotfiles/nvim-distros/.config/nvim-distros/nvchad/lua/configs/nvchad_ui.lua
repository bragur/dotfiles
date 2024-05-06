return {
	dependencies = {
		"abeldekat/harpoonline",
		config = function()
			require("harpoonline").setup({
				on_update = function()
					vim.cmd.redrawstatus()
				end,
			})
		end,
	},
}
