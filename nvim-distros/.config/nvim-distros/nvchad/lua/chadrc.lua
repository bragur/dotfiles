-- See https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "tokyonight",
	transparency = false,

	-- highlights
	hl_add = {
		FlashMatch = { bg = "black", fg = "pink" },
		FlashCurrent = { bg = "black", fg = "pink" },
		FlashLabel = { bg = "red", fg = "black" },
		FlashPrompt = { bg = "black", fg = "white" },
		FlashCursor = { bg = "teal", fg = "black" },
	},
	hl_override = {
		Function = { italic = true, bold = true },
		Comment = { fg = "light_grey" },
		Cursor = { fg = "blue", bg = "blue" },
		Bold = { bold = true },
		Italic = { italic = true },
		Boolean = { italic = true, fg = "yellow" },
		Keyword = { italic = false, bold = true },
		Structure = { italic = true },
		Visual = { bg = "light_grey" },
		St_VisualMode = { bg = "red" },
		Variable = { bold = true },
		Type = { italic = true, bold = true },
		Directory = { italic = true, fg = "teal" },
		Todo = { italic = true, bold = true, fg = "yellow" },
		Define = { italic = true },
		MiniCursorword = { italic = true },
	},

	cmp = {
		icons = true,
		lspkind_text = true,
		style = "default", -- default/flat_light/flat_dark/atom/atom_colored
	},

	statusline = {
		theme = "default", -- default/vscode/vscode_colored/minimal
		-- default/round/block/arrow separators work only for default statusline theme
		-- round and block will work for minimal theme only
		separator_style = "default",
		order = { "mode", "harpoon", "file", "git", "diagnostics", "%=", "lsp_msg", "%=", "lsp", "cursor", "cwd" },
		modules = {
			harpoon = function()
				return "%#St_file_bg# " .. require("harpoonline").format() .. " "
			end,
		},
	},

	nvdash = {
		load_on_startup = false,

		header = {
			"           ▄ ▄                   ",
			"       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ",
			"       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ",
			"    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ",
			"  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ",
			"  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄",
			"▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █",
			"█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █",
			"    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ",
		},

		buttons = {
			{ "  Find File", "Spc f f", "Telescope find_files" },
			{ "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
			{ "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
			{ "  Bookmarks", "Spc m a", "Telescope marks" },
			{ "  Themes", "Spc t h", "Telescope themes" },
			{ "  Mappings", "Spc c h", "NvCheatsheet" },
		},
	},
}

return M
