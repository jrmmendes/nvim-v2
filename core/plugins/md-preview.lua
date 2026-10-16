return {
  cmd = "MD",
  opts = {},
  build = function()
    local script = vim.fn.stdpath("config") .. "/core/custom/md-preview/server/build.sh"
    vim.notify("md-preview: building server (lazy build hook)…", vim.log.levels.INFO)
    local result = vim.system({ "bash", script }):wait(180000)
    if result.code == 0 then
      vim.notify("md-preview: server built", vim.log.levels.INFO)
    else
      local reason = result.stderr ~= "" and result.stderr or result.stdout
      vim.notify(
        "md-preview: server build failed: " .. vim.trim(reason or ""),
        vim.log.levels.ERROR
      )
    end
  end,
}
