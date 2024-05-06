return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      {
        "s1n7ax/nvim-window-picker",
        name = "window-picker",
        version = "2.*",
        event = "VeryLazy",
        opts = {
          hint = "floating-big-letter",
          filter_rules = {
            include_current_win = false,
            autoselect_one = true,
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify", "noice", "treesitter-context" },
              buftype = { "terminal", "quickfix" },
            },
          },
        },
      },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = { ".DS_Store" },
        },
      },
      window = {
        mappings = {
          ["S"] = "split_with_window_picker",
          ["s"] = "vsplit_with_window_picker",
          ["<cr>"] = "open_with_window_picker",
        },
      },
    },
    keys = {
      {
        "<leader>wp",
        function()
          local win = require("window-picker").pick_window()
          if win then
            vim.api.nvim_set_current_win(win)
          end
        end,
        desc = "Pick window",
      },
    },
  },
}
