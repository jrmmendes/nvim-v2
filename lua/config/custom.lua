-- Collector for local ("custom") plugins.
--
-- A local plugin tree lives in core/custom/<name>/ (pure plugin, entrypoint at
-- lua/<name>/init.lua). Its lazy.nvim spec lives in core/plugins/<name>.lua,
-- outside lua/ so it is NOT auto-imported by `import = "plugins"`. This module
-- loads every spec and injects `dir`/`name` so the spec files stay path-free.

local M = {}

local root = vim.fn.stdpath("config")
local specs_dir = root .. "/core/plugins"

function M.collect()
  local specs = {}
  for _, file in ipairs(vim.fn.glob(specs_dir .. "/*.lua", false, true)) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local ok, spec = pcall(dofile, file)
    if not ok then
      vim.notify(("failed to load custom plugin spec %q: %s"):format(name, spec), vim.log.levels.ERROR)
    elseif type(spec) == "table" then
      spec.dir = spec.dir or (root .. "/core/custom/" .. name)
      spec.name = spec.name or name
      specs[#specs + 1] = spec
    end
  end
  return specs
end

return M
