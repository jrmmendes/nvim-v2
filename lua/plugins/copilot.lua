return {
  "github/copilot.vim",
  lazy = false,
  init = function()
    -- Disable default mappings
    vim.g.copilot_no_tab_map = true
    -- Disable automatic directory changing
    vim.g.copilot_filetypes = { ["*"] = true }
    -- Disable automatic panel opening which might cause the lcd error
    vim.g.copilot_panel_command = ""
  end,
  config = function()
    vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false
    })
  end,
}
