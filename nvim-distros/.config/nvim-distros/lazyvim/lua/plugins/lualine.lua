return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "abeldekat/harpoonline", version = "*" },
    opts = function(_, opts)
      local hl = require("harpoonline")
      hl.setup({
        on_update = function()
          require("lualine").refresh()
        end,
      })

      opts.sections.lualine_z = { hl.format }

      return opts
    end,
  },
}
