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

local lastKey = ""
local lastBranch = ""

local function updateBranchKeymaps()
  if lastKey ~= getKey() or lastBranch ~= utils.getBranchName() then
    local harpoon = require("harpoon")
    local which_key = require("which-key")

    lastKey = getKey()
    lastBranch = utils.getBranchName() or ""

    local branch_name = utils.getBranchName()

    if branch_name ~= nil and branch_name ~= "" then
      local short_name = branch_name:match("([^/]+)$")
      if short_name ~= "main" and short_name ~= "master" then
        local prefix = "<leader>hb"
        local wk_branch_keys = {
          name = "⚓︎Git Branch",
          b = {
            function()
              harpoon.ui:toggle_quick_menu(
                harpoon:list(branch_name),
                { title = " ⚓︎Git branch: '" .. short_name .. "'" }
              )
            end,
            "Git Branch Catch",
          },
          a = {
            function()
              harpoon:list(branch_name):add()
            end,
            "Add Item",
          },
        }

        for i, item in ipairs(harpoon:list(branch_name).items) do
          local filename = "[Empty]"
          if item then
            filename = item.value:match("([^/]+)$")
          end
          local desc = "⚓︎" .. filename
          local f = function()
            harpoon:list(branch_name):select(i)
          end
          table.insert(wk_branch_keys, { [tostring(i)] = { f, desc } })
        end

        which_key.register({
          [prefix] = wk_branch_keys,
        })
      else
        which_key.register({
          ["<leader>hb"] = {
            name = "which_key_ignore",
            b = { nil, desc = "which_key_ignore" },
            a = { nil, desc = "which_key_ignore" },
          },
        })
      end
    end
  end
end

return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/which-key.nvim",
    },
    opts = {
      settings = {
        sync_on_toggle = true,
        sync_on_ui_close = true,
        key = getKey,
      },
      default = {
        display = function(list_item)
          return list_item.value:match("([^/]+)$")
        end,
      },
    },
    config = function(_, opts)
      local harpoon = require("harpoon")
      harpoon:setup(opts)
      updateBranchKeymaps()

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
    end,
    keys = function()
      local harpoon = require("harpoon")
      local keys = {
        {
          "<leader>ha",
          function()
            require("harpoon"):list():add()
          end,
          desc = "⚓︎Harpoon File",
        },
        {
          "<leader>hh",
          function()
            harpoon.ui:toggle_quick_menu(harpoon:list(), { title = " ⚓︎Current project" })
          end,
          desc = "⚓︎Harpoon Quick Menu",
        },
      }

      for i = 1, 5 do
        local item = require("harpoon"):list().items[i]
        local filename = "[Empty]"
        if item then
          filename = item.value:match("([^/]+)$")
        end
        local desc = "⚓︎" .. filename
        local cmd = function()
          harpoon:list():select(i)
        end
        table.insert(keys, { "<leader>" .. i, cmd, desc = desc })
      end

      updateBranchKeymaps()

      return keys
    end,
  },
}
