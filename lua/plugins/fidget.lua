return {
  'j-hui/fidget.nvim',
  opts = {
    window = {
      normal_hl = "Comment",      -- Base highlight group in the notification window
      winblend = 100,             -- Background color opacity in the notification window
      border = "none",            -- Border around the notification window
      zindex = 45,                -- Stacking priority of the notification window
      x_padding = 3,              -- Padding from right edge of window boundary
      y_padding = 2,              -- Padding from bottom edge of window boundary
      align = "bottom",           -- How to align the notification window
      relative = "editor",        -- What the notification window position is relative to
    },
    notification = {
      override_vim_notify = true
    }
  },
  config = function()
    require("fidget").setup()
    vim.notify = require("fidget").notify
  end,
}
