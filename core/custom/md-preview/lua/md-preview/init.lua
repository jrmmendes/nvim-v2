local M = {}

local configured = false
local opts = {}

local buf_slug = {}
local push_timers = {}
local push_group = nil

local function client()
  return require("md-preview.client")
end

local function url_encode(slug)
  return (slug:gsub("[^%w%-._~/]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

local function do_push(bufnr, info)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local final = client().register(info.port, info.slug, info.path, content)
  if final then
    info.slug = final
  end
end

local function push_buffer(bufnr, force)
  local info = buf_slug[bufnr]
  if not info then
    return
  end

  if force then
    do_push(bufnr, info)
    return
  end

  local timer = push_timers[bufnr]
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  timer = vim.uv.new_timer()
  push_timers[bufnr] = timer
  timer:start(200, 0, vim.schedule_wrap(function()
    local active = push_timers[bufnr]
    if active and not active:is_closing() then
      active:stop()
      active:close()
    end
    push_timers[bufnr] = nil
    do_push(bufnr, info)
  end))
end

local function ensure_push_autocmds()
  if push_group then
    return
  end
  push_group = vim.api.nvim_create_augroup("md-preview-push", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = push_group,
    callback = function(ev)
      push_buffer(ev.buf, false)
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = push_group,
    callback = function(ev)
      push_buffer(ev.buf, true)
    end,
  })
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    vim.notify("md-preview: save the buffer to a file first", vim.log.levels.ERROR)
    return
  end

  local path = vim.fn.fnamemodify(name, ":p")
  local slug = require("md-preview.slug").slug_for(path)
  local port = client().ensure(opts)
  if not port then
    vim.notify("md-preview: could not start the preview daemon", vim.log.levels.ERROR)
    return
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local final = client().register(port, slug, path, content) or slug
  buf_slug[bufnr] = { slug = final, port = port, path = path }
  ensure_push_autocmds()

  local url = ("http://127.0.0.1:%d/%s"):format(port, url_encode(final))
  if opts.theme and opts.theme ~= "auto" then
    url = url .. "?theme=" .. opts.theme
  end
  local ok = pcall(vim.ui.open, url)
  if not ok then
    vim.notify("md-preview: preview at " .. url, vim.log.levels.INFO)
  end
end

local function cleanup()
  buf_slug = {}
  for bufnr, timer in pairs(push_timers) do
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    push_timers[bufnr] = nil
  end
  if push_group then
    pcall(vim.api.nvim_del_augroup_by_id, push_group)
    push_group = nil
  end
end

function M.stop()
  local port = nil
  for _, info in pairs(buf_slug) do
    port = info.port
    break
  end
  client().shutdown(port)
  cleanup()
  vim.notify("md-preview: stopped", vim.log.levels.INFO)
end

function M.reload()
  local c = client()
  local state = c.read_state()
  c.shutdown(state and state.port or nil)
  if state and state.pid then
    local deadline = vim.uv.now() + 3000
    while vim.uv.now() < deadline and c.is_alive(state.pid) do
      vim.wait(50)
    end
  end
  cleanup()

  local built = c.build(opts)
  if not built then
    vim.notify("md-preview: reload aborted (server build failed)", vim.log.levels.ERROR)
    return
  end

  for name in pairs(package.loaded) do
    if name == "md-preview" or name:match("^md%-preview%.") then
      package.loaded[name] = nil
    end
  end

  local loaded, fresh = pcall(require, "md-preview")
  if not loaded or type(fresh) ~= "table" then
    vim.notify("md-preview: reload failed: " .. tostring(fresh), vim.log.levels.ERROR)
    return
  end

  local setup_ok, setup_err = pcall(fresh.setup, opts)
  if not setup_ok then
    vim.notify("md-preview: reload failed at setup: " .. tostring(setup_err), vim.log.levels.ERROR)
    return
  end
  vim.notify("md-preview: plugin reloaded", vim.log.levels.INFO)

  local port = require("md-preview.client").ensure(opts)
  if port then
    vim.notify("md-preview: daemon restarted on port " .. port, vim.log.levels.INFO)
  else
    vim.notify("md-preview: daemon did not start after reload", vim.log.levels.WARN)
  end
end

function M.start()
  return M.open()
end

function M.setup(new_opts)
  if configured then
    return
  end
  configured = true
  opts = vim.tbl_deep_extend("force", {
    port = 8765,
    idle_minutes = 15,
    theme = "auto",
    loader = "classic",
    auto_build = true,
  }, new_opts or {})

  vim.api.nvim_create_user_command("MD", function(args)
    local arg = vim.trim(args.args or "")
    if arg == "" then
      M.open()
    elseif arg == "stop" then
      M.stop()
    elseif arg == "reload" then
      M.reload()
    else
      vim.notify("md-preview: unknown argument " .. arg, vim.log.levels.WARN)
    end
  end, {
    nargs = "*",
    complete = function()
      return { "stop", "reload" }
    end,
    desc = "Markdown preview: start/ensure daemon and open, ':MD stop', or ':MD reload'",
  })
end

return M
