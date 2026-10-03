-- Options: single source of truth for all vim.opt / vim.o / vim.g settings.

local opt = vim.opt

-- Leader keys (must be set before keymaps.lua and lazy.nvim load).
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Line numbers.
opt.number = true
opt.relativenumber = true

-- Tabs / indentation.
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Text layout.
opt.textwidth = 80

-- Scrolling.
opt.scrolloff = 12

-- UI.
opt.showtabline = 0 -- no tabline; buffers/picker are used instead
opt.laststatus = 3 -- global statusline (config/statusline.lua)
opt.termguicolors = true
opt.signcolumn = "yes"
opt.showcmd = true
opt.guifont = "FiraCode Nerd Font:h13"

-- Buffers.
opt.hidden = true

-- Performance / responsiveness.
opt.updatetime = 300

-- System integration.
opt.clipboard = "unnamedplus"

-- Persistent undo.
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"

-- Window splitting.
opt.splitright = true
opt.splitbelow = true
