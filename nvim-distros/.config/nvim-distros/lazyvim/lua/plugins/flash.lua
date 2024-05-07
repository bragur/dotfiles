return {
  "folke/flash.nvim",
  keys = {
    { "s", nil },
    {
      "<leader>sf",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
  },
}
