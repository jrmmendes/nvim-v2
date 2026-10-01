-- Keymaps: single source of truth for global mappings.

local map = vim.keymap.set

-- Buffer navigation.
map("n", "<C-N>", ":bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<C-P>", ":bprev<CR>", { desc = "Previous buffer", silent = true })
map("n", "<C-D>", ":bdelete %<CR>", { desc = "Delete buffer", silent = true })

-- UI.
map("n", "<A-f>", function() Snacks.picker() end, { desc = "Picker (files)" })
map("n", "<Leader>m", ":Mason<CR>", { desc = "Mason", silent = true })
map("n", "<Leader>l", ":Lazy<CR>", { desc = "Lazy", silent = true })

-- Git.
map("n", "<A-d>", ":DiffviewToggle<CR>", { desc = "Toggle diffview", silent = true })

-- LSP.
map("n", "<leader>rn", function() vim.lsp.buf.rename() end, { desc = "Rename symbol" })
