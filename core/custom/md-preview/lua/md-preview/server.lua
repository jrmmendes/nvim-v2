local M = {}

local render = require("md-preview.render")

local server = nil
local clients = {}
local buf = nil
local path = nil
local root = nil
local port = nil
local version = 0
local augroup = nil
local fs_event = nil

local DEFAULT_PORT = 8765

local IMAGE_TYPES = {
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  svg = "image/svg+xml",
  webp = "image/webp",
  bmp = "image/bmp",
  ico = "image/x-icon",
  avif = "image/avif",
  tif = "image/tiff",
  tiff = "image/tiff",
}

local STATUS_TEXT = {
  [200] = "OK",
  [404] = "Not Found",
  [405] = "Method Not Allowed",
}

local function notify(msg, level)
  vim.notify("md-preview: " .. msg, level or vim.log.levels.WARN)
end

local function is_open(handle)
  return handle ~= nil and not handle:is_closing()
end

local function close_client(client)
  clients[client] = nil
  if is_open(client) then
    client:close()
  end
end

local function respond(client, status, content_type, body)
  if not is_open(client) then
    return
  end
  local head = ("HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"):format(
    status,
    STATUS_TEXT[status] or "OK",
    content_type,
    #body
  )
  client:write(head, function()
    if is_open(client) then
      client:write(body, function()
        close_client(client)
      end)
    end
  end)
end

local function buffer_text()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  end
  return ""
end

local function current_html()
  local title = "Markdown Preview"
  if path and path ~= "" then
    title = vim.fn.fnamemodify(path, ":t")
  end
  return render.page(title, render.to_html(buffer_text()))
end

local function image_type(name)
  local ext = name:match("%.([%a%d]+)$")
  return ext and IMAGE_TYPES[ext:lower()] or nil
end

local function serve_image(client, rel)
  rel = rel:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  if rel == "" or rel:sub(1, 1) == "/" or rel:find("..", 1, true) then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local full = root .. "/" .. rel
  local resolved = vim.fn.fnamemodify(full, ":p")
  if resolved:sub(1, #root + 1) ~= root .. "/" then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local stat = vim.uv.fs_stat(resolved)
  if not stat or stat.type ~= "file" then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local fd = vim.uv.fs_open(resolved, "r", 438)
  if not fd then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if not data then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  respond(client, 200, image_type(resolved) or "application/octet-stream", data)
end

local function handle(client, method, target)
  if method ~= "GET" then
    respond(client, 405, "text/plain; charset=utf-8", "method not allowed")
    return
  end
  local route = target:gsub("%?.*$", "")
  if route == "/" or route == "/index.html" then
    version = version + 1
    respond(client, 200, "text/html; charset=utf-8", current_html())
  elseif route == "/version" then
    respond(client, 200, "text/plain; charset=utf-8", tostring(version))
  elseif route:sub(1, 5) == "/img/" then
    serve_image(client, route:sub(6))
  else
    respond(client, 404, "text/plain; charset=utf-8", "not found")
  end
end

local function on_connection(err)
  if err or not is_open(server) then
    if err then
      notify("accept failed: " .. tostring(err), vim.log.levels.ERROR)
    end
    return
  end
  local client = vim.uv.new_tcp()
  server:accept(client)
  clients[client] = true
  local chunks = {}
  client:read_start(function(rerr, data)
    if rerr or not data then
      close_client(client)
      return
    end
    chunks[#chunks + 1] = data
    local request = table.concat(chunks)
    if #request > 65536 then
      close_client(client)
      return
    end
    if not request:find("\r\n\r\n", 1, true) then
      return
    end
    client:read_stop()
    local method, target = request:match("^(%u+) (%S+)")
    if not method then
      close_client(client)
      return
    end
    vim.schedule(function()
      handle(client, method, target)
    end)
  end)
end

local function bump()
  version = version + 1
end

local function reload_from_disk()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) or not path or path == "" then
    return
  end
  if vim.bo[buf].modified then
    return
  end
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return
  end
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if not data then
    return
  end
  local lines = vim.split(data, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if table.concat(current, "\n") ~= table.concat(lines, "\n") then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
end

local function watch_file()
  if not path or path == "" then
    return
  end
  local ok, handle = pcall(vim.uv.new_fs_event)
  if not ok or not handle then
    return
  end
  fs_event = handle
  pcall(function()
    handle:start(path, {}, vim.schedule_wrap(function()
      reload_from_disk()
      bump()
      if is_open(fs_event) then
        pcall(function()
          fs_event:stop()
        end)
      end
      fs_event = nil
      watch_file()
    end))
  end)
end

local function setup_autocmds()
  augroup = vim.api.nvim_create_augroup("md-preview-buffer", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    buffer = buf,
    callback = function()
      bump()
    end,
  })
end

function M.is_running()
  return is_open(server)
end

function M.start(opts)
  opts = opts or {}
  if M.is_running() then
    return true
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_buf(buf)
  else
    buf = vim.api.nvim_get_current_buf()
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    notify("save the buffer to a file first", vim.log.levels.ERROR)
    return false
  end
  path = vim.fn.fnamemodify(name, ":p")
  root = vim.fn.fnamemodify(path, ":h")
  port = tonumber(opts.port) or DEFAULT_PORT
  version = 0

  local handle = vim.uv.new_tcp()
  local _, bind_err = handle:bind("127.0.0.1", port)
  local _, listen_err = handle:listen(128, vim.schedule_wrap(on_connection))
  if bind_err or listen_err then
    if is_open(handle) then
      handle:close()
    end
    notify(("could not bind 127.0.0.1:%d (%s)"):format(port, tostring(listen_err or bind_err)), vim.log.levels.ERROR)
    return false
  end

  server = handle
  setup_autocmds()
  watch_file()

  local url = ("http://127.0.0.1:%d/"):format(port)
  notify("preview serving at " .. url, vim.log.levels.INFO)
  if opts.open ~= false then
    local opened, open_err = pcall(vim.ui.open, url)
    if not opened or open_err then
      notify("could not open browser, visit " .. url, vim.log.levels.WARN)
    end
  end
  return true
end

function M.stop()
  if is_open(fs_event) then
    pcall(function()
      fs_event:stop()
    end)
    fs_event:close()
  end
  fs_event = nil

  for client in pairs(clients) do
    if is_open(client) then
      client:close()
    end
  end
  clients = {}

  if is_open(server) then
    server:close()
  end
  server = nil

  if augroup then
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
    augroup = nil
  end

  buf = nil
  path = nil
  root = nil
  port = nil
  version = 0
end

function M.version()
  return version
end

return M
