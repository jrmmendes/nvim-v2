return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = ":call mkdp#util#install_sync()",
  config = function()
    vim.api.nvim_create_user_command("PreviewMD", function()
      vim.cmd("MarkdownPreviewToggle")
    end, { desc = "Toggle markdown preview in browser" })
  end,
}
