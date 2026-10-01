return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    local linters_by_ft = {
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      lua = { "luacheck" },
      python = { "ruff" },
      markdown = { "markdownlint" },
    }

    -- Only enable a linter when its executable is actually available
    -- (e.g. installed via :MasonInstall; Mason adds mason/bin to PATH).
    -- This prevents nvim-lint from failing on missing executables.
    local function installed(name)
      local cmd = lint.linters[name] and lint.linters[name].cmd
      if type(cmd) == "string" then
        name = cmd
      end
      return vim.fn.executable(name) == 1
    end

    for ft, names in pairs(linters_by_ft) do
      lint.linters_by_ft[ft] = vim.tbl_filter(installed, names)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
