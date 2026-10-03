return {
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.map").setup()
      vim.keymap.set("n", "<leader>mm", require("mini.map").toggle, { desc = "Toggle minimap" })
    end,
  },
  {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      require("mini.icons").mock_nvim_web_devicons()
    end,
  },
}
