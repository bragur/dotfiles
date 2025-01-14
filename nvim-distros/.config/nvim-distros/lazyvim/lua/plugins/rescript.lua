local tools = require("utils/rescript-tools")

return {
  {
    "rescript-lang/vim-rescript",
    ft = { "rescript" },
  },
  -- Set up custom treesitter for Rescript
  -- https://github.com/rescript-lang/tree-sitter-rescript
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "rescript",
      })

      --- @class ParserInfo[]
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.rescript = {
        install_info = {
          url = "https://github.com/rescript-lang/tree-sitter-rescript",
          branch = "main",
          files = { "src/scanner.c" },
          generate_requires_npm = false,
          requires_generate_from_grammar = true,
          use_makefile = true, -- macOS specific instruction
        },
      }
    end,
    init = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local which_key = require("which-key")

      require("lspconfig").rescriptls.setup({
        capabilities = capabilities,
        ---@diagnostic disable-next-line: missing-fields
        settings = {},
        filetypes = { "rescript" },
        cmd = { "rescript-language-server", "--stdio" },
        init_options = {
          extensionConfiguration = {
            askToStartBuild = false,
            -- inlayHints = { enable = false },
          },
        },
        commands = {
          ResOpenCompiled = {
            tools.open_compiled,
            description = "Open Compiled JS",
          },
          ResCreateInterface = {
            tools.create_interface,
            description = "Create Interface file",
          },
          ResSwitchImplInt = {
            tools.switch_impl_intf,
            description = "Switch Implementation/Interface",
          },
        },
      })

      which_key.add({ { "<leader>r", group = "ReScript" }, { "<leader>r_", hidden = true } })

      -- which_key.register({
      --   ["<leader>r"] = {
      --     name = "ReScript",
      --     _ = { nil, desc = "which_key_ignore" },
      --   },
      -- })
    end,
    keys = {
      {
        "<leader>rc",
        function()
          tools.open_compiled()
        end,
        desc = "Open Compiled Js",
        ft = "rescript",
      },
      {
        "<leader>ri",
        function()
          tools.create_interface(true)
        end,
        desc = "Create Interface file",
        ft = "rescript",
      },
      {
        "<leader>rx",
        function()
          tools.switch_impl_intf(true)
        end,
        desc = "Switch Impl/Interface",
        ft = "rescript",
      },
      { "<leader>rr", "<cmd>LspStart<cr>", desc = "Start LSP", ft = "rescript" },
    },
  },
}
