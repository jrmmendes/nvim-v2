return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'main',
    lazy = false,
    config = function()
      require('nvim-treesitter').setup({
        ensure_installed = { 'lua', 'vim', 'javascript', 'typescript' }, -- Add languages you use
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end
  },
}
