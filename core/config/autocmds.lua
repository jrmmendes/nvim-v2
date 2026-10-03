-- Autocmds: single source of truth for autocmds (deduplicated).

-- Enforce consistent indentation (previously defined twice).
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  pattern = "*",
  callback = function()
    vim.bo.expandtab = true
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Set the current file's directory as the working directory (with safeguards
-- for special buffers and unnamed buffers).
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local buftype = vim.bo.buftype
    if buftype == "" and vim.fn.expand("%:p") ~= "" then
      vim.cmd("silent! lcd %:p:h")
    end
  end,
})

-- Start treesitter highlighting and indentation for the filetypes whose
-- parsers are installed (see plugins/nvim-treesitter.lua).
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "lua", "vim", "vimdoc", "query",
    "javascript", "typescript", "tsx",
    "json", "yaml",
    "markdown", "markdown_inline",
    "bash", "html", "css",
  },
  callback = function()
    vim.treesitter.start()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
