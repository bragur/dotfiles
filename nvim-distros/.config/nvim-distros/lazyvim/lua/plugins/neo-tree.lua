return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        width = 55,
      },
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = {
            ".DS_Store",
          },
          never_show_by_pattern = {
            "*/.dotfiles/COMMIT_EDITMSG",
            "*/.dotfiles/FETCH_HEAD",
            "*/.dotfiles/HEAD",
            "*/.dotfiles/ORIG_HEAD",
            "*/.dotfiles/config",
            "*/.dotfiles/description",
            "*/.dotfiles/hooks",
            "*/.dotfiles/index",
            "*/.dotfiles/info",
            "*/.dotfiles/logs",
            "*/.dotfiles/objects",
            "*/.dotfiles/refs",
          },
        },
      },
    },
  },
}
