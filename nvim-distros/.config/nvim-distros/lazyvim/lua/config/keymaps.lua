-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set -- Shortcut for mapping
local del = vim.keymap.del -- Shortcut for deleting

map("n", "<leader>fs", "<cmd>w<cr>", { noremap = true, silent = true, desc = "Save file" })
del("t", "<Esc><Esc>", {})

-- Move Lines adjusted from LazyVim https://github.com/LazyVim/LazyVim/blob/97480dc5d2dbb717b45a351e0b04835f138a9094/lua/lazyvim/config/keymaps.lua#L25
map("n", "∆", "<cmd>m .+1<cr>==", { desc = "which_key_ignore" })
map("n", "¬", "<cmd>m .-2<cr>==", { desc = "which_key_ignore" })
map("v", "∆", ":m '>+1<cr>gv=gv", { desc = "which_key_ignore" })
map("v", "¬", ":m '<-2<cr>gv=gv", { desc = "which_key_ignore" })

-- Copy lines and visual blocks
map("n", "<A-S-j>", "<cmd>t.<cr>", { desc = "Duplicate Line ↓" })
map("n", "˝", "<cmd>t.<cr>", { desc = "which_key_ignore" })
map("n", "<A-S-k>", "<cmd>t-1<cr>", { desc = "Duplicate Line ↑" })
map("n", "˛", "<cmd>t-1<cr>", { desc = "which_key_ignore" })
map("x", "<A-S-j>", require("utils").duplicateLinesDown, { desc = "Duplicate Selection ↓" })
map("x", "˝", require("utils").duplicateLinesDown, { desc = "which_key_ignore" })
map("x", "<A-S-k>", require("utils").duplicateLinesUp, { desc = "Duplicate Selection ↑" })
map("x", "˛", require("utils").duplicateLinesUp, { desc = "which_key_ignore" })

-- Join lines but keep spot
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zzzv'", { noremap = true, expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zzzv'", { noremap = true, expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward].'zz'", { noremap = true, expr = true, desc = "Prev Search Result" })

-- Window
map("n", "<leader>ws", "<cmd>sp<cr>", { desc = "Vertical Split" })
map("n", "<leader>ws", "<cmd>vsp<cr>", { desc = "Horizontal Split" })
map("n", "<leader>wf", "<cmd>only<cr>", { desc = "Delete Other windows" })

-- Motion
map("n", "]h", "]hzz", { desc = "Next Change" })
map("n", "[h", "[hzz", { desc = "Previous Change" })

-- Quick access to dotfiles
map("n", "<leader>fd", function()
  require("telescope.builtin").find_files({
    cwd = "~/.dotfiles",
    hidden = true,
    prompt_title = "Find Dotfiles",
    results_title = "~/.dotfiles/",
    preview_title = "Preview",
  })
end, { desc = "Find Dotfiles" })

-- LazyGit in Tmux popup
map("n", "<leader>gg", function()
  vim.fn.system('tmux popup -d "#{pane_current_path}" -xC -yC -w80% -h80% -E lazygit')
end, { desc = "Lazygit" })
del("n", "<leader>gG", {})
del("n", "<leader>-", {})
