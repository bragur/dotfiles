local utils = require("utils")

-- Key harpoons based on project roots
local function getKey(default)
	default = default or vim.loop.cwd()
	local root = utils.getWorkspaceRoot()

	if root ~= nil and root ~= "" then
		return root
	else
		return default
	end
end

local function updateKeymaps()
	local harpoon = require("harpoon")
	local map = vim.keymap.set

	for i = 1, 5 do
		utils.safeDeleteKeymap("n", "<leader>" .. i)
		local item = require("harpoon"):list().items[i]
		local filename = "[Empty]"

		if item then
			filename = item.value:match("([^/]+)$")
		end

		local desc = "⚓︎" .. filename

		local cmd = function()
			harpoon:list():select(i)
		end

		map("n", "<leader>" .. i, cmd, { desc = desc })
	end
end

local lastKey = ""
local lastBranch = ""

local function updateBranchKeymaps()
	if lastKey ~= getKey() or lastBranch ~= utils.getBranchName() then
		local harpoon = require("harpoon")
		local map = vim.keymap.set

		lastKey = getKey()
		lastBranch = utils.getBranchName() or ""

		local branch_name = utils.getBranchName()

		utils.safeDeleteKeymap("n", "<leader>hbb")
		utils.safeDeleteKeymap("n", "<leader>hba")

		if branch_name ~= nil and branch_name ~= "" then
			local short_name = branch_name:match("([^/]+)$")
			if short_name ~= "main" and short_name ~= "master" then
				require("mnemonics_helpers").setFolders(short_name)

				map("n", "<leader>hbb", function()
					harpoon.ui:toggle_quick_menu(
						harpoon:list(branch_name),
						{ title = " ⚓︎Git branch: '" .. short_name .. "'" }
					)
				end, { desc = "Harpoon Quick Menu" })
				map("n", "<leader>hba", function()
					harpoon:list(branch_name):append()
				end, { desc = "Harpoon Add Item" })
			end
		end

		updateKeymaps()
	end
end

local function split_path(path)
	-- Pattern to capture the directory part and the filename part of a path
	-- Assumes paths are in a format recognizable by the OS running Neovim (e.g., POSIX)
	local directory, filename = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	return directory, filename
end

return {
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/which-key.nvim",
	},
	config = function()
		local harpoon = require("harpoon")

		local opts = {
			settings = {
				sync_on_toggle = true,
				sync_on_ui_close = true,
				key = getKey,
			},
			default = {
				display = function(list_item)
					local filename = list_item.value:match("([^/]+)$")
					return filename
				end,
			},
		}

		harpoon:setup(opts)

		updateBranchKeymaps()

		local map = vim.keymap.set
		local events = require("harpoon.extensions").event_names
		harpoon:extend({
			[events.ADD] = function()
				updateBranchKeymaps()
			end,
			[events.REMOVE] = function()
				updateBranchKeymaps()
			end,
			[events.REORDER] = function()
				updateBranchKeymaps()
			end,
			[events.LIST_READ] = function()
				updateBranchKeymaps()
			end,
		})

		local augroup = vim.api.nvim_create_augroup("HarpoonNeogitEvents", { clear = true })
		vim.api.nvim_create_autocmd("User", {
			pattern = "NeogitBranchCheckout",
			group = augroup,
			callback = updateBranchKeymaps,
		})

		map("n", "<leader>hh", function()
			harpoon.ui:toggle_quick_menu(harpoon:list(), { title = " ⚓︎Current project" })
		end, { desc = "Harpoon Quick Menu" })
		map("n", "<leader>ha", function()
			harpoon:list():add()
		end, { desc = "Harpoon Add Item" })
	end,
}
