-- Collector for every plugin spec in core/plugins/.
--
-- External plugins (lazy installs from git) and local ("custom") plugins live
-- side by side, one file per concern, as core/plugins/<name>.lua. External
-- specs are plain lazy.nvim specs. A local plugin additionally has a pure
-- plugin tree at core/custom/<name>/ (entrypoint lua/<name>/init.lua); for those
-- this module injects `dir`/`name` so the spec files stay path-free.
--
-- This replaces lazy's `import = "plugins"`, which would force the specs into a
-- lua/plugins/ tree. Importing them explicitly keeps core/ flat.

local M = {}

local root = vim.fn.stdpath("config")
local specs_dir = root .. "/core/plugins"

function M.collect()
  local specs = {}
  for _, file in ipairs(vim.fn.glob(specs_dir .. "/*.lua", false, true)) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local ok, spec = pcall(dofile, file)
    if not ok then
      vim.notify(("failed to load plugin spec %q: %s"):format(name, spec), vim.log.levels.ERROR)
    elseif type(spec) == "table" then
      if vim.uv.fs_stat(root .. "/core/custom/" .. name) then
        spec.dir = spec.dir or (root .. "/core/custom/" .. name)
        spec.name = spec.name or name
      end
      specs[#specs + 1] = spec
    end
  end
  return specs
end

return M
