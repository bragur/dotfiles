-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- When focus is gained scroll the screen without moving the cursor
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    local cur_buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(cur_buf) then
      vim.cmd("normal! zH")
    end
  end,
})
