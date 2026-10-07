-- Neovim resolves `require()` only from `lua/` directories on the runtimepath.
-- This config keeps its modules flat under `core/` (no `lua/` layer), so add the
-- config root to package.path to make `require("core.*")` resolve.
local root = vim.fn.stdpath("config")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

require("core.config.options")
require("core.config.keymaps")
require("core.config.autocmds")
require("core.config.statusline").setup()
require("core.config.lazy")
