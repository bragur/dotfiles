local function logging_snippets(luasnip)
  local add = luasnip.add_snippets
  local s = luasnip.snippet
  local t = luasnip.text_node
  local i = luasnip.insert_node

  add("rescript", {
    s("blog", {
      t("Js.log2(`BB ${__MODULE__}, line ${Js.Int.toString(__LINE__)}:\\n`, ("),
      i(1),
      t("))"),
    }),
  })
  add("rescript", {
    s("flog", {
      t('Js\\.log[\\d]?\\([\\n ]*["`]BB'),
    }),
  })
end

local function custom_snippets(luasnip)
  logging_snippets(luasnip)
end

return {
  {
    "L3MON4D3/LuaSnip",
    config = function(_, opts)
      local ls = require("luasnip")
      if opts then
        ls.config.setup(opts)
      end

      vim.tbl_map(function(type)
        require("luasnip.loaders.from_" .. type).lazy_load()
      end, { "vscode", "snipmate", "lua" })

      require("luasnip.loaders.from_vscode").lazy_load({
        paths = vim.fn.stdpath("config") .. "/snippets/",
      })

      ls.config.set_config({
        -- Use <TAB> to store visual selection into selection_keys
        store_selection_keys = "<Tab>",
      })

      -- ls.filetype_extend("rescript", { "rescriptdoc" })
      custom_snippets(ls)
    end,
  },
}
