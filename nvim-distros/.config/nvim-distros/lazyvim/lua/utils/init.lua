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
    ---@diagnostic disable-next-line: undefined-field
    if keymap.lhs == lhs then
      return true
    end
  end
  return false
end

function M.safeDeleteKeymap(mode, lhs)
  lhs = vim.api.nvim_replace_termcodes(lhs, true, false, true)
  LazyVim.notify("Attempting to delete: '" .. lhs .. "'")
  if M.keymapExists(mode, lhs) then
    LazyVim.notify("Deleting keymap: '" .. lhs .. "'")
    vim.keymap.del(mode, lhs, {})
  end
end

function M.existsInList(list, item)
  for _, value in ipairs(list) do
    if value == item then
      return true
    end
  end
  return false
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
    M.notify("Error opening process: " .. tostring(err))
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
    M.notify("Error opening process: " .. tostring(err))
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

function M.run_in_alt_window()
  local winnrs = vim.tbl_filter(function(w)
    local win_conf = vim.api.nvim_win_get_config(w)
    if win_conf.relative ~= "" and not win_conf.focusable then
      return false
    end
    if w == vim.api.nvim_get_current_win() then
      return false
    end
    return true
  end, vim.api.nvim_list_wins())

  if winnrs[1] == nil then
    -- Should open new split
    vim.cmd("vsplit")
  else
    -- Use other split
    vim.api.nvim_set_current_win(winnrs[1])
  end
end

function M.expand_env_variables(path)
  -- Expand variables like $VAR/ or $VAR at the end of the string
  local expanded_path = path:gsub("%$([%w_]+)/", function(var)
    local value = os.getenv(var)
    if value then
      return value .. "/" -- Append the slash after the expanded value
    else
      return "$" .. var .. "/" -- Keep the original if no env var found
    end
  end)

  -- Special handling for when the variable is at the end of the string with no trailing slash
  expanded_path = expanded_path:gsub("%$([%w_]+)$", function(var)
    return os.getenv(var) or ("$" .. var)
  end)

  return expanded_path
end

return M
