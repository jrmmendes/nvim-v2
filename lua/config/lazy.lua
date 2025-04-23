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

-- line numbers
vim.opt.number = true             
vim.opt.relativenumber = true

vim.opt.showtabline = 0           -- Disable tabline
vim.opt.autoindent = true         -- Auto indent new lines
vim.opt.smartindent = true        -- Smart auto indenting
vim.opt.tabstop = 2               -- Number of spaces per tab
vim.opt.shiftwidth = 2            -- Number of spaces for each step of autoindent
vim.opt.expandtab = true          -- Convert tabs to spaces
vim.opt.textwidth = 80            -- Maximum width of text
vim.opt.hidden = true 
vim.opt.showcmd = true
vim.opt.scrolloff = 12

-- fzf remmaps
vim.keymap.set('n', '<A-z>', ':Files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-c>', ':Commands<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-h>', ':History<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-f>', ':Rg<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-t>', ':Tags<CR>', { noremap = true, silent = true })

-- mason
vim.keymap.set('n', '<Leader>m', ':Mason<CR>', { noremap = true, silent = true })

-- Lazy
vim.keymap.set('n', '<Leader>l', ':Lazy<CR>', { noremap = true, silent = true })

-- Dooing
vim.api.nvim_create_user_command("Todo", function()
  vim.cmd("Dooing")
end, { desc = "Open Dooing for managing todos" })

-- buffer keymaps
vim.keymap.set('n', '<C-N>', ':bnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-P>', ':bprev<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-D>', ':bdelete %<CR>', { noremap = true, silent = true })

-- LSP keymaps
vim.keymap.set('n', '<S-F6>', vim.lsp.buf.rename, { desc = "LSP Rename" })


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

-- force expandtabs behavior in yaml
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
      vim.opt_local.expandtab = true
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
    end,
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

-- Enforce expandtab for all buffers
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    pattern = "*",
    callback = function()
      vim.bo.expandtab = true
      vim.bo.tabstop = 2
      vim.bo.shiftwidth = 2
    end,
  })

