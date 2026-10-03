-- lazy.nvim bootstrap. Leader keys and options live in core/config/options.lua.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = require("core.config.custom").collect(),
  install = { colorscheme = { "gruvbox" } },
  checker = { enabled = false },
})

-- Workaround for an upstream lazy.nvim race.
--
-- The view's `update()` is wrapped in `Util.throttle`, which renders through
-- `lazy.async` (a coroutine resumed on a later event-loop tick). So `:Lazy`
-- returns before `render:update()` has set `render.locations`. A key already in
-- the typeahead (e.g. `<Leader>l` followed by <CR>) is then handled by the
-- details keymap while `locations` is still nil, and `get_plugin`/`get_row`
-- crash with "bad argument #1 to 'ipairs' (table expected, got nil)".
-- Guard the lookups until the first render populates `locations`.
do
  local Render = require("lazy.view.render")
  local get_plugin, get_row = Render.get_plugin, Render.get_row
  Render.get_plugin = function(self, row)
    if self.locations == nil then
      return
    end
    return get_plugin(self, row)
  end
  Render.get_row = function(self, selected)
    if self.locations == nil then
      return
    end
    return get_row(self, selected)
  end
end
