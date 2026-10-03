return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    lazy = false,
    config = function()
      -- Parsers (and their queries) are installed by the new `install` API.
      -- Highlighting/indentation are enabled per filetype in config/autocmds.lua.
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "query",
        "javascript", "typescript", "tsx",
        "json",
        "markdown", "markdown_inline",
        "bash", "html", "css",
      })
    end,
  },
}
