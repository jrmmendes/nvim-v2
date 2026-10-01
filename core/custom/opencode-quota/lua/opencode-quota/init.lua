local M = {}

local configured = false
local panel = nil
local loading_id = nil

local function hide_loading()
  if not loading_id then
    return
  end
  if _G.Snacks and _G.Snacks.notifier then
    pcall(_G.Snacks.notifier.hide, loading_id)
  end
  loading_id = nil
end

function M.setup(opts)
  if configured then
    return
  end
  configured = true
  opts = opts or {}

  vim.api.nvim_create_user_command("OpencodeQuota", function()
    M.show()
  end, { desc = "Show OpenCode Go usage quotas" })
end

function M.fetch(cb)
  -- curl completes in a fast event context; hop to the main loop so callers can
  -- safely touch UI/vim API (e.g. lazily loading Snacks.win, which creates
  -- augroups).
  cb = vim.schedule_wrap(cb)

  local key, err = require("opencode-quota.auth").resolve()
  if not key then
    cb(nil, err)
    return
  end
  require("opencode-quota.client").fetch(key, cb)
end

function M.show()
  if panel and panel.win and vim.api.nvim_win_is_valid(panel.win) then
    panel:close()
    panel = nil
    return
  end
  hide_loading()
  loading_id = vim.notify("Fetching OpenCode quota...", vim.log.levels.INFO, {
    title = "OpenCode Quota",
    timeout = false,
  })
  M.fetch(function(data, err)
    hide_loading()
    panel = require("opencode-quota.ui").render(data, err) or nil
  end)
end

return M
