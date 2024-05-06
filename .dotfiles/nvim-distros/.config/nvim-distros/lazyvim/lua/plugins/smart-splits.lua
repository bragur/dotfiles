return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    keys = function()
      local ss = require("smart-splits")
      local function easy_toggle(activate)
        local utils = require("utils")
        local pane_count_output = vim.fn.system("tmux list-panes | wc -l")
        -- Clean up the output to ensure it's just the numeric count
        -- Trim any leading/trailing whitespace including newlines
        pane_count_output = pane_count_output:gsub("^%s*(.-)%s*$", "%1")
        local pane_count = tonumber(pane_count_output)
        if pane_count == 1 then
          -- Reset tmuxifier session layout instead of the following
          vim.fn.system("tmux split-window -h -l 33% -c '" .. utils.getWorkspaceRoot() .. "'")
          if not activate then
            vim.fn.system("tmux last-pane")
          end
        else
          if activate then
            vim.fn.system("tmux last-pane")
          else
            vim.fn.system("tmux resize-pane -Z")
          end
        end
      end

      local keys = {
        -- recommended mappings
        -- resizing splits
        -- these keymaps will also accept a range,
        -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
        { "<A-h>", require("smart-splits").resize_left, desc = "Resize Left" },
        { "<A-j>", require("smart-splits").resize_down, desc = "Resize Down" },
        { "<A-k>", require("smart-splits").resize_up, desc = "Resize Up" },
        { "<A-l>", require("smart-splits").resize_right, desc = "Resize Right" },
        -- swapping buffers between windows
        { "<leader><leader>h", require("smart-splits").swap_buf_left, desc = "Swap Buffer Left" },
        { "<leader><leader>j", require("smart-splits").swap_buf_down, desc = "Swap Buffer Down" },
        { "<leader><leader>k", require("smart-splits").swap_buf_up, desc = "Swap Buffer Up" },
        { "<leader><leader>l", require("smart-splits").swap_buf_right, desc = "Swap Buffer Right" },
        {
          "<C-_>",
          function()
            easy_toggle(false)
          end,
          desc = "Peek runner term",
          silent = true,
        },
        {
          "\\",
          function()
            easy_toggle(true)
          end,
          desc = "Toggle runner term",
        },
        -- cursor movements
        { "<C-h>", ss.move_cursor_left, desc = "Move Cursor Left" },
        { "<C-j>", ss.move_cursor_down, desc = "Move Cursor Down" },
        { "<C-k>", ss.move_cursor_up, desc = "Move Cursor Up" },
        { "<C-l>", ss.move_cursor_right, desc = "Move Cursort Right" },
      }

      return keys
    end,
  },
}
