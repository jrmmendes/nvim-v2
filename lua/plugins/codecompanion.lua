return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "j-hui/fidget.nvim"
  },
  config = function()
    require("codecompanion").setup({
      opts = {
        log_level = "DEBUG", -- or "TRACE"
      }
    })

    require("plugins.codecompanion.fidget-spinner"):init()  
  end
}
