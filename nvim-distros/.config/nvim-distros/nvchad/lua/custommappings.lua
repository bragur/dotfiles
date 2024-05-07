local mnemonics = require("mnemonics_helpers")
local map = vim.keymap.set -- Shortcut for mapping
local nomap = vim.keymap.del -- Shortcut for unmapping

-- Sets names of Which Key containers (folders)
require("utils").notify("Setting base mnemonics")
mnemonics.setBaseNames()

-- better up/down from LazyVim https://github.com/LazyVim/LazyVim/blob/97480dc5d2dbb717b45a351e0b04835f138a9094/lua/lazyvim/config/keymaps.lua#L7
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

-- Move Lines from LazyVim https://github.com/LazyVim/LazyVim/blob/97480dc5d2dbb717b45a351e0b04835f138a9094/lua/lazyvim/config/keymaps.lua#L25
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "∆", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("n", "¬", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "∆", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("i", "¬", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "∆", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
map("v", "¬", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Copy lines and visual blocks
map("n", "<A-S-j>", "<cmd>t.<cr>", { desc = "Duplicate Line ↓" })
map("n", "˝", "<cmd>t.<cr>", { desc = "Duplicate Line ↓" })
map("n", "<A-S-k>", "<cmd>t-1<cr>", { desc = "Duplicate Line ↑" })
map("n", "˛", "<cmd>t-1<cr>", { desc = "Duplicate Line ↑" })
map("x", "<A-S-j>", require("utils").duplicateLinesDown, { desc = "Duplicate Selection ↓" })
map("x", "˝", require("utils").duplicateLinesDown, { desc = "Duplicate Selection ↓" })
map("x", "˛", require("utils").duplicateLinesUp, { desc = "Duplicate Selection ↑" })

-- Remap quick terms
nomap("n", "<leader>h")
map("n", "<leader>H", function()
	require("nvchad.term").new({ pos = "sp", size = 0.3 })
end, { desc = "Terminal New horizontal term" })
nomap("n", "<leader>v")
map("n", "<leader>V", function()
	require("nvchad.term").new({ pos = "vsp", size = 0.3 })
end, { desc = "Terminal New vertical term" })

-- Tmux Navigation
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "Switch Window Left" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "Switch Window Down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "Switch Window Up" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "Switch Window Right" })

-- Spacemacs styles
map("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>qq", "<cmd>qall<cr>", { desc = "Quit" })

-- Window management
map("n", "<leader>+", "<cmd>vertical resize +5<cr>", { desc = "Increase Width" })
map("n", "<leader>-", "<cmd>vertical resize -5<cr>", { desc = "Decrease Width" })
map("n", "<leader>w1", "<cmd>only<cr>", { desc = "Close All But Current Window" })

-- Join lines but keep spot
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zzzv'", { noremap = true, expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zzzv'", { noremap = true, expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Prev Search Result" })

-- Add undo break points
map("i", ".", ".<C-g>u")
map("i", ",", ",<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")
map("i", "(", "(<C-g>u")
map("i", ")", ")<C-g>u")
map("i", "[", "[<C-g>u")
map("i", "]", "]<C-g>u")
map("i", "{", "{<C-g>u")
map("i", "}", "}<C-g>u")

-- Indents
map("v", ">", ">gv", { desc = "Indent" }) -- Indent and rehighlight
map("v", "<", "<gv", { desc = "Outdent" }) -- Outdent and rehighlight

-- Get to config easily
map("n", "<leader>fc", function()
	require("telescope.builtin").find_files({
		hidden = true, -- Include hidden files
		cwd = "/$HOME/.config/nvim/", -- Set your predefined directory path here
	})
end, { noremap = true, silent = true, desc = "Config Find" })

nomap("n", "<leader>b")
nomap("n", "<leader>x")
map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "Buffer new" })
map("n", "<leader>bd", function()
	require("nvchad.tabufline").close_buffer()
end, { desc = "Buffer delete" })

map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "Tab new" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Tab delete" })
map("n", "<leader><tab><tab>", "<cmd>tabnext<cr>", { desc = "Tab next" })
map("n", "<leader><tab><S-Tab>", "<cmd>tabprevious<cr>", { desc = "Tab previous" })
