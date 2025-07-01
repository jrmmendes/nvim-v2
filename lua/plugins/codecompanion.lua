return {
  { "github/copilot.vim" },
  {
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ibhagwan/fzf-lua", -- Add fzf-lua for enhanced FZF UI
    },
    "olimorris/codecompanion.nvim",
    config = function()
      require('codecompanion').setup {
        strategies = {
          chat = {
            slash_commands = {
              ["file"] = {
                opts = {
                  provider = "fzf_lua",
                  contains_code = true
                }
              }
            }
          }
        },
        display = {
          action_pallete = {
            provide = "fzf_lua",
            opts = {
              winopts = {
                height = 0.6, -- 60% of the screen height
                width = 0.6,  -- 60% of the screen width
                row = 0.2,    -- 20% from the top
                col = 0.2,    -- 20% from the left
                border = 'rounded',
                preview = {
                  layout = 'vertical',
                  vertical = 'up:50%',
                },
              },
              fzf_opts = {
                ['--layout'] = 'reverse',
                ['--info'] = 'inline',
                ['--prompt'] = 'CodeCompanion> ',
              },
            }
          }
        }
      }
    end
  }
}
