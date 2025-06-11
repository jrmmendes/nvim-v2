return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter", -- Load cmp when entering insert mode
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP completion source
      "hrsh7th/cmp-buffer",   -- Buffer completion source
      "hrsh7th/cmp-path",     -- Path completion source
      "saadparwaiz1/cmp_luasnip", -- Snippet completion (if you use luasnip)
      "L3MON4D3/LuaSnip",     -- Snippet engine itself (if using luasnip)
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip') -- Requires LuaSnip plugin

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body) -- For `cmp_luasnip`
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(), -- Manually trigger completion
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept selected item. Set `select = false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- LSP source
          { name = 'luasnip' },  -- Snippet source
          { name = 'buffer' },   -- Current buffer words
          { name = 'path' },     -- File system paths
        }),
      })
    end,
  }
