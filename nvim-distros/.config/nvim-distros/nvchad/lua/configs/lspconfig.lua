local on_attach = require("nvchad.configs.lspconfig").on_attach
-- local on_init = require("nvchad.configs.lspconfig").on_init
-- local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

return {
	opts = function()
		-- chad_config.defaults()

		local M = {
			jsonls = {
				settings = {
					json = {
						format = {
							enable = true,
						},
					},
					validate = { enable = true },
				},
			},
			rescriptls = {
				cmd = { "rescript-language-server", "--stdio" },
				lazy = false,
				commands = {
					ResOpenCompiled = {
						require("rescript-tools").open_compiled,
						description = "Open Compiled JS",
					},
					ResCreateInterface = {
						require("rescript-tools").create_interface,
						description = "Create Interface file",
					},
					ResSwitchImplInt = {
						require("rescript-tools").switch_impl_intf,
						description = "Switch Implementation/Interface",
					},
				},
				settings = {
					codeLens = true,
				},
			},
			tsserver = {
				cmd = { "typescript-language-server", "--stdio" },
				init_options = {
					preferences = {
						disableSuggestions = false,
					},
				},
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
				},
				root_dir = function()
					return vim.loop.cwd()
				end,
			},
		}

		local servers = {
			html = {},
			cssls = {},
			jsonls = M.jsonls,
			rescriptls = M.rescriptls,
			tsserver = M.tsserver,
		}

		for name, opts in pairs(servers) do
			opts.on_attach = on_attach
			-- opts.on_init = on_init
			-- opts.capabilities = capabilities
			lspconfig[name].setup(opts)
		end
	end,
}

-- local configs = {
-- 	jsonls = {
-- 		settings = {
-- 			json = {
-- 				format = {
-- 					enable = true,
-- 				},
-- 			},
-- 			validate = { enable = true },
-- 		},
-- 	},
-- 	rescriptls = {
-- 		cmd = { "rescript-language-server", "--stdio" },
-- 		lazy = false,
-- 		commands = {
-- 			ResOpenCompiled = {
-- 				require("rescript-tools").open_compiled,
-- 				description = "Open Compiled JS",
-- 			},
-- 			ResCreateInterface = {
-- 				require("rescript-tools").create_interface,
-- 				description = "Create Interface file",
-- 			},
-- 			ResSwitchImplInt = {
-- 				require("rescript-tools").switch_impl_intf,
-- 				description = "Switch Implementation/Interface",
-- 			},
-- 		},
-- 		settings = {
-- 			codeLens = true,
-- 		},
-- 	},
-- 	tsserver = {
-- 		cmd = { "typescript-language-server", "--stdio" },
-- 		init_options = {
-- 			preferences = {
-- 				disableSuggestions = false,
-- 			},
-- 		},
-- 		filetypes = {
-- 			"javascript",
-- 			"javascriptreact",
-- 			"javascript.jsx",
-- 			"typescript",
-- 			"typescriptreact",
-- 			"typescript.tsx",
-- 		},
-- 		root_dir = function()
-- 			return vim.loop.cwd()
-- 		end,
-- 	},
-- }
--
-- for name, opts in pairs(configs) do
-- 	require("utils").notify("Setting up " .. name)
-- 	opts.on_attach = on_attach
-- 	opts.on_init = on_init
-- 	opts.capabilities = capabilities
-- 	lspconfig[name].setup(opts)
-- end
