return {
  "neovim/nvim-lspconfig",
  init = function()
    local utils = require("utils")
    local keys = require("lazyvim.plugins.lsp.keymaps").get()
    -- change a keymap
    keys[#keys + 1] = {
      "gd",
      function()
        utils.run_in_alt_window()
        require("telescope.builtin").lsp_definitions({ reuse_win = false })
      end,
      desc = "Goto Definition",
      has = "definition",
    }
    keys[#keys + 1] = {
      "gD",
      function()
        utils.run_in_alt_window()
        vim.lsp.buf.declaration()
      end,
      desc = "Goto Definition",
      has = "definition",
    }
    keys[#keys + 1] = {
      "gI",
      function()
        utils.run_in_alt_window()
        require("telescope.builtin").lsp_implementations({ reuse_win = true })
      end,
      desc = "Goto Definition",
      has = "definition",
    }
    -- disable a keymap
    -- keys[#keys + 1] = { "K", false }
    -- add a keymap
    -- keys[#keys + 1] = { "H", "<cmd>echo 'hello'<cr>" }
  end,
}
