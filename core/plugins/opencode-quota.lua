return {
  dependencies = { "folke/snacks.nvim" },
  cmd = "OpencodeQuota",
  keys = {
    { "<leader>oq", function() require("opencode-quota").show() end, desc = "OpenCode Quota" },
  },
  opts = {},
}
