local M = {}

local URL = "https://opencode.ai/zen/go/v1/usage"

local function split_status(out)
  local pos = out:match(".*()\n")
  if not pos then
    return out, nil
  end
  return out:sub(1, pos - 1), tonumber(out:sub(pos + 1))
end

function M.fetch(key, cb)
  local args = {
    "curl",
    "-sS",
    "--max-time",
    "15",
    -- No -L: do not follow redirects; keep the request pinned to the canonical
    -- host. These flags are defensive in case curl is configured to follow.
    "--proto-redir",
    "=https",
    "--max-redirs",
    "0",
    "-H",
    "Authorization: Bearer " .. key,
    "-H",
    "Accept: application/json",
    "-w",
    "\n%{http_code}",
    URL,
  }

  vim.system(args, { text = true }, function(res)
    if res.code ~= 0 then
      local detail = (res.stderr or ""):gsub("%s+$", "")
      cb(nil, ("network failure (curl exit %d): %s"):format(res.code, detail))
      return
    end

    local body, status = split_status(res.stdout or "")
    if status == 401 then
      cb(nil, "invalid OpenCode Go key or no Go plan (HTTP 401)")
      return
    elseif status == 403 then
      cb(nil, "forbidden (HTTP 403)")
      return
    elseif status ~= 200 then
      cb(nil, ("unexpected response (HTTP %s): %s"):format(tostring(status), body))
      return
    end

    local ok, data = pcall(vim.json.decode, body)
    if not ok then
      cb(nil, "failed to decode usage response as JSON")
      return
    end
    cb(data, nil)
  end)
end

return M
