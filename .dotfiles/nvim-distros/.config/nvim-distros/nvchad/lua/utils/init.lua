local M = {}

function M.notify(msg, level)
	level = level or vim.log.levels.INFO

	vim.defer_fn(function()
		vim.notify(msg, level)
	end, 1000)
end

function M.mergeTables(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
	return t1
end

function M.keymapExists(mode, lhs)
	local keymaps = vim.api.nvim_get_keymap(mode)
	for _, keymap in ipairs(keymaps) do
		if keymap.lhs == lhs then
			return true
		end
	end
	return false
end

function M.safeDeleteKeymap(mode, lhs)
	lhs = vim.api.nvim_replace_termcodes(lhs, true, false, true)
	if M.keymapExists(mode, lhs) then
		vim.keymap.del(mode, lhs)
	end
end

function M.duplicateLinesDown()
	-- Execute initial duplication
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("y'>p", true, false, true), "x", false)
	-- Find original selection positions
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local num_lines = end_line - start_line + 1

	-- Reselect lines, offset by new lines (e.g. selecting the new lines)
	local reselectKeys = tostring(start_line + num_lines) .. "GV" .. tostring(end_line + num_lines) .. "G"
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(reselectKeys, true, false, true), "n", false)
end

function M.duplicateLinesUp()
	-- Execute initial duplication
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("yP", true, false, true), "x", false)
	-- Find original selection positions
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local num_lines = end_line - start_line + 1

	-- Reselect lines, offset by new lines (e.g. selecting the new lines)
	local reselectKeys = tostring(start_line - num_lines) .. "GV" .. tostring(end_line - num_lines) .. "G"
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(reselectKeys, true, false, true), "n", false)
end

function M.getWorkspaceRoot()
	local handle, err = io.popen("git rev-parse --show-toplevel 2> /dev/null")
	if not handle then
		require("utils").notify("Error opening process: " .. tostring(err))
		return nil
	end

	local git_root = handle:read("*a")
	handle:close()

	if git_root then
		git_root = string.gsub(git_root, "\n$", "")
		return git_root
	else
		return nil
	end
end

function M.getBranchName()
	local handle, err = io.popen("git rev-parse --abbrev-ref HEAD 2> /dev/null")
	if not handle then
		require("utils").notify("Error opening process: " .. tostring(err))
		return nil
	end

	local branch_name = handle:read("*a")
	handle:close()

	if branch_name then
		branch_name = string.gsub(branch_name, "\n$", "")
		return branch_name
	else
		return nil
	end
end
return M
