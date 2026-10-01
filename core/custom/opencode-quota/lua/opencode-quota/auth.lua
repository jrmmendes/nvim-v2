local M = {}

local function auth_path()
  local data_home = vim.env.XDG_DATA_HOME
  if not data_home or data_home == "" then
    data_home = vim.fn.expand("~/.local/share")
  end
  return data_home .. "/opencode/auth.json"
end

local function extract_key(entry)
  if type(entry) == "string" then
    return entry
  end
  if type(entry) == "table" then
    return entry.key or entry.apiKey or entry.access
  end
  return nil
end

function M.resolve()
  local path = auth_path()
  if vim.fn.filereadable(path) == 1 then
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok and lines then
      local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
      if decoded_ok and type(decoded) == "table" then
        local key = extract_key(decoded["opencode-go"])
        if type(key) == "string" and key ~= "" then
          return key
        end
      end
    end
  end

  local env_key = vim.env.OPENCODE_GO_API_KEY
  if type(env_key) == "string" and env_key ~= "" then
    return env_key
  end

  return nil,
    ("no OpenCode Go credential found: expected %q in %s or OPENCODE_GO_API_KEY"):format(
      "opencode-go",
      path
    )
end

return M
