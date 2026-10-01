return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = function() vim.fn["mkdp#util#install"]() end,
  config = function()
    vim.api.nvim_create_user_command("PreviewMD", function()
      vim.cmd("MarkdownPreviewToggle")
    end, { desc = "Toggle markdown preview in browser" })
  end,
}
