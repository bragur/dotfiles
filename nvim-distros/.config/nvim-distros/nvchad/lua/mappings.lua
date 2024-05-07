require("nvchad.mappings")
require("custommappings")

local map = vim.keymap.set

-- map("n", ";", ":", { desc = "CMD enter command mode" })

map("n", "<leader>fm", function()
	require("conform").format()
end, { desc = "File Format with conform" })
map("i", "jk", "<ESC>", { desc = "Escape insert mode" })
