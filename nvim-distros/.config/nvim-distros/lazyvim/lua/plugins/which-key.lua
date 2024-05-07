return {
  "folke/which-key.nvim",
  opts = function(_, opts)
    if LazyVim.has("harpoon") then
      opts.defaults["<leader>h"] = { name = "+harpoon" }
    end
  end,
}
