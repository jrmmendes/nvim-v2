-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.number = true             -- Show line numbers
vim.opt.showtabline = 0           -- Disable tabline
vim.opt.autoindent = true         -- Auto indent new lines
vim.opt.smartindent = true        -- Smart auto indenting
vim.opt.tabstop = 2               -- Number of spaces per tab
vim.opt.shiftwidth = 2            -- Number of spaces for each step of autoindent
vim.opt.expandtab = true          -- Convert tabs to spaces
vim.opt.textwidth = 80            -- Maximum width of text
vim.opt.hidden = true 
vim.opt.showcmd = true
vim.opt.scrolloff = 5

-- buffer keymaps
vim.keymap.set('n', '<C-N>', ':bnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-P>', ':bprev<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-D>', ':bdelete %<CR>', { noremap = true, silent = true })

-- set current file as working directory (with safeguards for special buffers)
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- Only change directory for normal buffers with real files
    local buftype = vim.bo.buftype
    if buftype == "" and vim.fn.expand("%:p") ~= "" then
      vim.cmd('silent! lcd %:p:h')
    end
  end
})

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "darcula" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

--vim.api.nvim_set_option("clipboard","unnamed")
