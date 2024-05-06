require("nvchad.autocmds")

-- -- Custom autocommands
-- local autocmd = vim.api.nvim_create_autocmd
-- autocmd("BufEnter", {
-- 	pattern = { "~/.config/nvim-distros/*", "~/.config/nvim-distros/**/*" },
-- 	callback = function()
-- 		-- Set 'autochdir' locally for this buffer to change the working directory
-- 		print("Setting autochdir")
-- 		vim.opt_local.autochdir = true
-- 	end,
-- })

local ignore_filetypes = { "NvimTree" }

local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	callback = function(_)
		if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
			vim.b.focus_disable = true
		else
			vim.b.focus_disable = false
		end
	end,
	desc = "Disable focus autoresize for FileType",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "rescript",
	callback = function()
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<leader>tr",
			":lua require('nvchad.term').runner({pos = 'vsp', cmd = 'yarn build', id = 'resbld', clear_cmd = false})<cr>",
			{ noremap = true, silent = true }
		)
	end,
})

-- close some filetypes with <q>
-- vim.api.nvim_create_autocmd("FileType", {
--   group = augroup("close_with_q"),
--   pattern = {
--     "PlenaryTestPopup",
--     "help",
--     "lspinfo",
--     "notify",
--     "qf",
--     "query",
--     "spectre_panel",
--     "startuptime",
--     "tsplayground",
--     "neotest-output",
--     "checkhealth",
--     "neotest-summary",
--     "neotest-output-panel",
--   },
--   callback = function(event)
--     vim.bo[event.buf].buflisted = false
--     vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
--   end,
-- })
