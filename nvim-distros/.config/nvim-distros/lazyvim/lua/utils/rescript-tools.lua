local M = {}

local notifyOpts = { timeout = 6000 }

---@brief [[
---Author: Pedro Castro
---Homepage: <https://github.com/aspeddro/rescript-tools.nvim>
---License: MIT
---@brief ]]

local METHODS = {
  createInterface = "textDocument/createInterface",
  openCompiled = "textDocument/openCompiled",
}

---Get extension file
---@param name string
---@return string
local get_extension = function(name)
  return string.match(name, ".[^.]+$")
end

---Get active rescript lsp client
---@return table|nil
local get_client = function()
  local active_client = vim.lsp.get_active_clients({ name = "rescriptls" })
  return not vim.tbl_isempty(active_client) and active_client[1] or nil
end

---Open file
---@param path string Path of file
---@return nil
local open_file = function(path)
  if vim.api.nvim_buf_get_name(0) == path then
    return
  end

  require("utils").run_in_alt_window()
  vim.cmd.edit(path)
end

---Switch between implementation and interface file
---@param ask? boolean Ask to create interface file if not exists. Default is `false`
M.switch_impl_intf = function(ask)
  local bufnr = 0

  if vim.filetype.match({ buf = bufnr }) ~= "rescript" then
    vim.notify("rescript: This command only can run on *.res or *.resi files.", vim.log.levels.INFO, notifyOpts)
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)

  local current_file_extension = get_extension(name)

  if current_file_extension == ".resi" then
    -- Go to implementation .res
    open_file(string.sub(name, 0, string.len(name) - 1))
    return
  elseif current_file_extension == ".res" then
    -- Go to Interface .resi
    -- if interface doesn't exist, ask the user before creating.
    local path = name .. "i"
    local interface_exists = vim.loop.fs_stat(path) ~= nil
    if not interface_exists and ask then
      vim.ui.select({ "No", "Yes" }, {
        prompt = "Do you want to create an interface *.resi:",
      }, function(choice)
        if choice == "Yes" then
          M.create_interface(true)
        end
      end)
    end

    if interface_exists then
      open_file(path)
      return
    end
  else
    vim.notify("rescript: Failed to detect extension for " .. name, vim.log.levels.ERROR, notifyOpts)
  end
end

---Create Interface file
---@param open? boolean Open interface file after create. Default is `false`
---@usage [[
--- require('rescript-tools').create_interface()
--- -- Open file after create
--- require('rescript-tools').create_interface(true)
---@usage ]]
M.create_interface = function(open)
  local client = get_client()

  local bufnr = 0
  local name = vim.api.nvim_buf_get_name(0)

  if vim.loop.fs_stat(name .. "i") ~= nil then
    vim.notify("rescript: Interface file already exists", vim.log.levels.INFO, notifyOpts)
    M.switch_impl_intf(false)
    return
  end

  if client then
    client.request(METHODS.createInterface, vim.lsp.util.make_text_document_params(bufnr), function(_, result, _)
      if result then
        if open then
          open_file(vim.uri_to_fname(result.uri))
        end
      end
    end, bufnr)
  end
end

---Open Compiled JavaScript
M.open_compiled = function()
  local bufnr = 0
  local client = get_client()

  if client then
    client.request(METHODS.openCompiled, vim.lsp.util.make_text_document_params(bufnr), function(_, result, _)
      if result then
        open_file(vim.uri_to_fname(result.uri))
      end
    end, bufnr)
  end
end

return M
