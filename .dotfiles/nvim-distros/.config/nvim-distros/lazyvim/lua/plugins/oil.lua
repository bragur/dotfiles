return {
  {
    "stevearc/oil.nvim",
    enabled = false,
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    view_options = {
      show_hidden = true,
    },
    keys = {
      { "-", "<cmd>Oil<cr>", { desc = "Oil: Toggle" } },
    },
  },
}
