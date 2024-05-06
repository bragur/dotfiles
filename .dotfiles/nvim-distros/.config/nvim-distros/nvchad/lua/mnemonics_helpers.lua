local which_key = require("which-key")

local function tableToWhichKeyRegisters(t)
	local M = {}

	for key, value in pairs(t) do
		M[key] = {
			name = value,
		}
	end

	return M
end

local base = tableToWhichKeyRegisters({
	b = "Buffer",
	c = "Code",
	f = "Find",
	g = "Git",
	h = "Harpoon",
	l = "l",
	p = "p",
	r = "r",
	s = "Split",
	t = "Tabs",
	w = "w",
	x = "Trouble",
})

local M = {}

function M.setBaseNames(branchName)
	if branchName then
		base["hb"] = { name = "⚓︎Git branch: " .. branchName }
	end
	-- Prefix naming
	which_key.register(base, { prefix = "<leader>" })
end

function M.setFolders(branchName)
	-- which_key.reset()
	M.setBaseNames(branchName)
end

return M
