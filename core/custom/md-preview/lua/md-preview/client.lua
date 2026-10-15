local M = {}

local DEFAULT_PORT = 8765
local DEFAULT_IDLE = 15

local function state_dir()
  return vim.fn.stdpath("state") .. "/md-preview"
end

local function state_path()
  return state_dir() .. "/daemon.json"
end

function M.state_path()
  return state_path()
end

function M.read_state()
  local ok, lines = pcall(vim.fn.readfile, state_path())
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(data) ~= "table" then
    return nil
  end
  return data
end

function M.write_state(port)
  vim.fn.mkdir(state_dir(), "p")
  local file = state_path()
  local tmp = file .. ".tmp"
  local payload = vim.json.encode({ pid = vim.uv.os_getpid(), port = port })
  local handle = io.open(tmp, "w")
  if not handle then
    return false
  end
  handle:write(payload)
  handle:close()
  return os.rename(tmp, file) ~= nil
end

function M.clear_state()
  os.remove(state_path())
end

function M.is_alive(pid)
  if type(pid) ~= "number" then
    return false
  end
  local ok, result = pcall(vim.uv.kill, pid, 0)
  return ok and result ~= nil
end

function M.request(port, method, path, body, timeout_ms)
  if not port then
    return nil
  end
  body = body or ""
  local tcp = vim.uv.new_tcp()
  if not tcp then
    return nil
  end

  local chunks = {}
  local done = false
  local failed = false

  local payload = ("%s %s HTTP/1.0\r\nHost: 127.0.0.1\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s"):format(
    method,
    path,
    #body,
    body
  )

  local function stop()
    if tcp and not tcp:is_closing() then
      pcall(function()
        tcp:read_stop()
      end)
    end
    done = true
  end

  tcp:connect("127.0.0.1", port, function(cerr)
    if cerr then
      failed = true
      stop()
      return
    end
    tcp:write(payload, function(werr)
      if werr then
        failed = true
        stop()
        return
      end
      tcp:read_start(function(rerr, data)
        if rerr then
          failed = true
          stop()
          return
        end
        if not data then
          stop()
          return
        end
        chunks[#chunks + 1] = data
      end)
    end)
  end)

  vim.wait(timeout_ms or 2000, function()
    return done
  end, 10)

  if tcp and not tcp:is_closing() then
    pcall(function()
      tcp:close()
    end)
  end

  if failed then
    return nil
  end
  local response = table.concat(chunks)
  if response == "" then
    return nil
  end
  local head, resp_body = response:match("^(.-)\r\n\r\n(.*)$")
  if not head then
    return nil
  end
  local status = tonumber(head:match("^HTTP/%d%.%d (%d+)"))
  return status, resp_body
end

function M.spawn(opts)
  opts = opts or {}
  local source = debug.getinfo(1, "S").source:sub(2)
  local plugin_dir = vim.fn.fnamemodify(source, ":p:h:h:h")
  local config_dir = vim.fn.stdpath("config")
  local data_site = vim.fn.stdpath("data") .. "/site"
  local cmd = {
    vim.v.progpath,
    "--headless",
    "-u",
    "NONE",
    "--cmd",
    "set rtp+=" .. config_dir,
    "--cmd",
    "set rtp+=" .. plugin_dir,
    "--cmd",
    "set rtp+=" .. data_site,
    "--cmd",
    "lua require('md-preview.daemon').run()",
  }
  return vim.fn.jobstart(cmd, {
    detach = true,
    env = {
      MDPRV_PORT = tostring(opts.port or DEFAULT_PORT),
      MDPRV_IDLE = tostring(opts.idle_minutes or DEFAULT_IDLE),
    },
  })
end

function M.ensure(opts)
  opts = opts or {}
  local state = M.read_state()
  if state and state.pid and state.port and M.is_alive(state.pid) then
    local status = M.request(state.port, "GET", "/__health", nil, 300)
    if status == 200 then
      return state.port
    end
  end

  M.spawn(opts)

  local deadline = vim.uv.now() + 5000
  while vim.uv.now() < deadline do
    local current = M.read_state()
    if current and current.pid and current.port and M.is_alive(current.pid) then
      local status = M.request(current.port, "GET", "/__health", nil, 300)
      if status == 200 then
        return current.port
      end
    end
    vim.wait(100, function()
      return false
    end, 20)
  end
  return nil
end

function M.register(port, slug, path, content)
  if not port then
    return nil
  end
  local body = vim.json.encode({ slug = slug, path = path, content = content })
  local status, resp = M.request(port, "PUT", "/__register", body, 3000)
  if status ~= 200 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, resp)
  if ok and type(data) == "table" and type(data.slug) == "string" then
    return data.slug
  end
  return slug
end

function M.shutdown(port)
  if not port then
    local state = M.read_state()
    port = state and state.port
  end
  if not port then
    return false
  end
  M.request(port, "POST", "/__shutdown", nil, 1000)
  return true
end

return M
