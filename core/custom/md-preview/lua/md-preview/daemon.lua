local M = {}

local render = require("md-preview.render")

M._stopped = false

local server = nil
local clients = {}
local slugs = {}
local fs_events = {}
local idle_timer = nil
local last_activity = 0
local port = nil
local idle_ms = 15 * 60 * 1000
local state_dir = nil
local state_file = nil

local DEFAULT_PORT = 8765
local DEFAULT_IDLE = 15

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
  [400] = "Bad Request",
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

local function respond(client, status, content_type, body, on_close)
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
        if on_close then
          on_close()
        end
      end)
    end
  end)
end

local function touch()
  last_activity = vim.uv.now()
end

local function write_state()
  if not state_file then
    return
  end
  vim.fn.mkdir(state_dir, "p")
  local tmp = state_file .. ".tmp"
  local payload = vim.json.encode({ pid = vim.uv.os_getpid(), port = port })
  local handle = io.open(tmp, "w")
  if not handle then
    return
  end
  handle:write(payload)
  handle:close()
  os.rename(tmp, state_file)
end

local function clear_state()
  if state_file then
    os.remove(state_file)
  end
end

local function normalized(content)
  if content == "" or content:sub(-1) == "\n" then
    return content
  end
  return content .. "\n"
end

local function read_file(path)
  if not path or path == "" then
    return nil
  end
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  return data
end

local function image_type(name)
  local ext = name:match("%.([%a%d]+)$")
  return ext and IMAGE_TYPES[ext:lower()] or nil
end

local function short_hash(text)
  local h = 0
  for i = 1, #text do
    h = (h * 31 + text:byte(i)) % 4294967296
  end
  return ("%08x"):format(math.floor(h))
end

local shutdown

local function watch_slug(slug)
  local entry = slugs[slug]
  if not entry or entry.path == "" or fs_events[slug] then
    return
  end
  local ok, handle = pcall(vim.uv.new_fs_event)
  if not ok or not handle then
    return
  end
  fs_events[slug] = handle
  pcall(function()
    handle:start(entry.path, {}, vim.schedule_wrap(function()
      local current = slugs[slug]
      if current and current.path ~= "" then
        local data = read_file(current.path)
        if data then
          current.content = data
          current.version = (current.version or 0) + 1
        end
      end
      local active = fs_events[slug]
      if is_open(active) then
        pcall(function()
          active:stop()
        end)
      end
      fs_events[slug] = nil
      watch_slug(slug)
    end))
  end)
end

local function serve_image(client, rel)
  local best_slug, best_len = nil, 0
  for slug in pairs(slugs) do
    if (rel == slug or rel:sub(1, #slug + 1) == slug .. "/") and #slug > best_len then
      best_slug, best_len = slug, #slug
    end
  end
  if not best_slug then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local entry = slugs[best_slug]
  local rest = rel:sub(best_len + 1)
  rest = rest:gsub("^/", "")

  if rest == "" or rest:sub(1, 1) == "/" or rest:find("..", 1, true) then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local root = entry.dir
  if not root or root == "" then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  local full = root .. "/" .. rest
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

local function serve_slug(client, route)
  local slug = route:sub(2)
  local version_route = false
  if slug:sub(-8) == "/version" then
    slug = slug:sub(1, #slug - 8)
    version_route = true
  end

  local entry = slugs[slug]
  if not entry then
    respond(client, 404, "text/plain; charset=utf-8", "not found")
    return
  end

  if version_route then
    respond(client, 200, "text/plain; charset=utf-8", tostring(entry.version or 0))
    return
  end

  local content = entry.content
  if content == nil then
    content = read_file(entry.path) or ""
  end
  local title = entry.path ~= "" and vim.fn.fnamemodify(entry.path, ":t") or "Markdown Preview"
  respond(client, 200, "text/html; charset=utf-8", render.page(title, render.to_html(normalized(content))))
end

local function register_slug(client, body)
  local ok, data = pcall(vim.json.decode, body)
  if not ok or type(data) ~= "table" or type(data.slug) ~= "string" or data.slug == "" then
    respond(client, 400, "text/plain; charset=utf-8", "bad request")
    return
  end

  local slug = data.slug
  local path = type(data.path) == "string" and data.path or ""
  local entry = slugs[slug]
  if entry and path ~= "" and entry.path ~= path then
    slug = slug .. "-" .. short_hash(path)
    entry = slugs[slug]
  end

  if not entry then
    entry = { path = "", dir = "", content = nil, version = 0 }
    slugs[slug] = entry
    watch_slug(slug)
  end

  if path ~= "" then
    entry.path = vim.fn.fnamemodify(path, ":p")
    entry.dir = vim.fn.fnamemodify(entry.path, ":p:h")
  end
  if data.content ~= nil then
    entry.content = data.content
  end
  entry.version = (entry.version or 0) + 1

  respond(client, 200, "application/json; charset=utf-8", vim.json.encode({ slug = slug }))
end

local function handle(client, method, target, body)
  touch()
  local route = target:gsub("%?.*$", "")
  route = route:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)

  if method ~= "GET" and method ~= "HEAD" and method ~= "PUT" and method ~= "POST" then
    respond(client, 405, "text/plain; charset=utf-8", "method not allowed")
    return
  end

  if (method == "GET" or method == "HEAD") and route == "/__health" then
    respond(client, 200, "text/plain; charset=utf-8", "ok")
  elseif method == "PUT" and route == "/__register" then
    register_slug(client, body)
  elseif method == "POST" and route == "/__shutdown" then
    respond(client, 200, "text/plain; charset=utf-8", "bye", function()
      vim.schedule(shutdown)
    end)
  elseif method == "GET" or method == "HEAD" then
    if route:sub(1, 5) == "/img/" then
      serve_image(client, route:sub(6))
    else
      serve_slug(client, route)
    end
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
    if #request > 1048576 then
      close_client(client)
      return
    end
    local header_end = request:find("\r\n\r\n", 1, true)
    if not header_end then
      return
    end
    local head = request:sub(1, header_end - 1)
    local length = tonumber(head:match("[Cc]ontent%-[Ll]ength:%s*(%d+)")) or 0
    local body = request:sub(header_end + 4)
    if #body < length then
      return
    end
    client:read_stop()
    local method, target = request:match("^(%u+) (%S+)")
    if not method then
      close_client(client)
      return
    end
    if length > 0 then
      body = body:sub(1, length)
    end
    vim.schedule(function()
      handle(client, method, target, body)
    end)
  end)
end

shutdown = function()
  if M._stopped then
    return
  end
  M._stopped = true

  if idle_timer then
    if not idle_timer:is_closing() then
      idle_timer:stop()
      idle_timer:close()
    end
    idle_timer = nil
  end

  for slug, handle in pairs(fs_events) do
    if is_open(handle) then
      pcall(function()
        handle:stop()
      end)
      handle:close()
    end
    fs_events[slug] = nil
  end

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

  clear_state()
end

function M.run()
  port = tonumber(vim.env.MDPRV_PORT) or DEFAULT_PORT
  idle_ms = (tonumber(vim.env.MDPRV_IDLE) or DEFAULT_IDLE) * 60 * 1000
  state_dir = vim.fn.stdpath("state") .. "/md-preview"
  state_file = state_dir .. "/daemon.json"
  last_activity = vim.uv.now()

  local handle = vim.uv.new_tcp()
  local _, bind_err = handle:bind("127.0.0.1", port)
  local _, listen_err = handle:listen(128, vim.schedule_wrap(on_connection))
  if bind_err or listen_err then
    if is_open(handle) then
      handle:close()
    end
    notify(("could not bind 127.0.0.1:%d (%s)"):format(port, tostring(listen_err or bind_err)), vim.log.levels.ERROR)
    vim.cmd("qa!")
    return
  end

  server = handle
  write_state()

  idle_timer = vim.uv.new_timer()
  idle_timer:start(30000, 30000, vim.schedule_wrap(function()
    if vim.uv.now() - last_activity > idle_ms then
      shutdown()
    end
  end))

  while not M._stopped do
    vim.wait(3600000, function()
      return M._stopped
    end, 100)
  end
  vim.cmd("qa!")
end

return M
