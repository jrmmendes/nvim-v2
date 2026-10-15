local M = {}

local configured = false
local opts = {}

local function run(fn)
  if vim.in_fast_event() then
    vim.schedule(fn)
    return
  end
  return fn()
end

local function server()
  return require("md-preview.server")
end

local function do_toggle()
  local srv = server()
  if srv.is_running() then
    srv.stop()
    vim.notify("md-preview: stopped", vim.log.levels.INFO)
    return
  end
  local ok, started = pcall(srv.start, opts)
  if not ok then
    vim.notify("md-preview: " .. tostring(started), vim.log.levels.ERROR)
  end
end

function M.setup(new_opts)
  if configured then
    return
  end
  configured = true
  opts = new_opts or {}

  -- Warm up treesitter on the main loop so later parses never create the query
  -- cache augroup from a fast event context (which raises E5560).
  run(function()
    pcall(function()
      require("md-preview.render").to_html("warmup")
    end)
  end)

  vim.api.nvim_create_user_command("PreviewMD", M.toggle, {
    desc = "Toggle markdown preview in browser",
  })

  local group = vim.api.nvim_create_augroup("md-preview", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      server().stop()
    end,
  })
end

function M.toggle()
  return run(do_toggle)
end

function M.start()
  return run(function()
    return server().start(opts)
  end)
end

function M.stop()
  return run(function()
    server().stop()
  end)
end

return M
