local utils = require("utils")

local plugins = {
	tmux_navigator = "christoomey/vim-tmux-navigator",
	copilot = "github/copilot.vim",
	lspconfig = "neovim/nvim-lspconfig",
	rescript = "rescript-lang/vim-rescript",
	rescript_tools = "aspeddro/rescript-tools.nvim",
	nvim_surround = "kylechui/nvim-surround",
	neogit = "NeogitOrg/neogit",
	nvim_focus = "nvim-focus/focus.nvim",
	harpoon = "ThePrimeagen/harpoon",
	harpoonline = "abeldekat/harpoonline",
	nvchad_ui = "NvChad/ui",
	vimux = "preservim/vimux",
	oil = "stevearc/oil.nvim",
	illuminate = "RRethy/vim-illuminate",
	hardtime = "m4xshen/hardtime.nvim",
	trouble = "folke/trouble.nvim",
	noice = "folke/noice.nvim",
	telescope_project = "nvim-telescope/telescope-project.nvim",
	flash = "folke/flash.nvim",
	cursorword = "echasnovski/mini.cursorword",
}

local MyPlugins = {}

for key, value in pairs(plugins) do
	MyPlugins[key] = function(enabled)
		local plugin = {
			value,
			enabled = enabled,
		}

		local status, config = pcall(require, "configs." .. key)
		if status and type(config) == "table" then
			plugin = utils.mergeTables(plugin, config)
		end
		if status and type(config) ~= "table" then
			utils.notify("Custom Plugins Warning: Configuration for plugin '" .. key .. "' did not return a table.")
		end

		return plugin
	end
end

---@type NvPluginSpec[]
return {
	MyPlugins.tmux_navigator(true),
	MyPlugins.hardtime(false),
	MyPlugins.copilot(true),
	MyPlugins.lspconfig(true),
	MyPlugins.rescript(true),
	MyPlugins.rescript_tools(true),
	MyPlugins.nvim_surround(true),
	MyPlugins.neogit(true),
	MyPlugins.nvim_focus(true),
	MyPlugins.harpoon(true),
	MyPlugins.harpoonline(true),
	MyPlugins.nvchad_ui(true),
	MyPlugins.vimux(true),
	MyPlugins.oil(true),
	MyPlugins.illuminate(false),
	MyPlugins.trouble(true),
	MyPlugins.noice(true),
	MyPlugins.telescope_project(true),
	MyPlugins.flash(true),
	MyPlugins.cursorword(true),
}
