return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "folke/snacks.nvim",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            slash_commands = {
              ["file"] = {
                opts = {
                  provider = "snacks",
                  contains_code = true,
                },
              },
            },
          },
        },
        display = {
          action_palette = {
            provider = "snacks",
            opts = {
              provider = "snacks",
              name = "CodeCompanion",
            },
          },
        },
      })
    end,
  },
}
