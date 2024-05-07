return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      file_ignore_patterns = {
        "^COMMIT_EDITMSG$",
        "^FETCH_HEAD$",
        "^HEAD$",
        "^ORIG_HEAD$",
        "^config$",
        "^description$",
        "^hooks/",
        "^index$",
        "^info/",
        "^logs/",
        "^objects/",
        "^refs/",
      },
    },
  },
  keys = {
    {
      "<leader>fa",
      LazyVim.telescope("files", { hidden = true, no_ignore = true }),
      desc = "Find All Files (Root Dir)",
    },
    {
      "<leader>fA",
      LazyVim.telescope("files", { cwd = false, hidden = true, no_ignore = true }),
      desc = "Find All Files (cwd)",
    },
  },
}
