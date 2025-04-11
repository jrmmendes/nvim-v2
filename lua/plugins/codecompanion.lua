return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  config = function()
    require("codecompanion").setup({
        opts = {
          log_level = "DEBUG", -- or "TRACE"
        }
      })
  end
}
