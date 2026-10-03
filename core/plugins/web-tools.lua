return {
  "ray-x/web-tools.nvim",
  config = function()
    require("web-tools").setup({
      keymaps = {
        rename = nil, -- use the lspconfig default
      },
      hurl = {
        show_headers = false,
        floating = false,
        json5 = false,
        formatters = {
          json = { "jq" },
          html = { "prettier", "--parser", "html" },
        },
      },
    })
  end,
}
