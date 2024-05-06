return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        json = { "prettier" },
        zsh = { "shfmt" },
      },
    },
  },
}
