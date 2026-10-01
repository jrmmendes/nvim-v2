local M = {}

local NAMED = {
  { key = "rolling", label = "Rolling usage" },
  { key = "weekly", label = "Weekly usage" },
  { key = "monthly", label = "Monthly usage" },
}

local RESET_FIELDS = { "resetsAt", "resets_at", "resetAt", "reset_at", "reset", "resets" }
local PERCENT_FIELDS =
  { "percent", "used", "usage", "used_percent", "usedPercent", "percent_used" }

local WIDTH = 44
local FILL = "█"
local PAD = "  "
local PAD_LEN = #PAD

local function theme_color(group, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl and hl[attr] then
    return hl[attr]
  end
  return fallback
end

-- Resolve from the active theme on every render so a colorscheme switch is
-- picked up without stale hardcoded colors.
local function ensure_hl()
  local accent = theme_color("GruvboxOrange", "fg", 0xfe8019)
  local warn = theme_color("GruvboxYellow", "fg", 0xfabd2f)
  local err = theme_color("GruvboxRed", "fg", 0xfb4934)
  local label = theme_color("GruvboxFg1", "fg", 0xebdbb2)
  local dim = theme_color("GruvboxGray", "fg", 0x928374)
  local badge_bg = theme_color("GruvboxBg2", "fg", 0x504945)
  local track = theme_color("GruvboxBg3", "fg", 0x665c54)
  local panel_bg = theme_color("NormalFloat", "bg", 0x3c3836)
  local panel_fg = theme_color("NormalFloat", "fg", 0xebdbb2)

  local specs = {
    { "OpenCodeQuotaNormal", { fg = panel_fg, bg = panel_bg } },
    { "OpenCodeQuotaNormalNC", { fg = panel_fg, bg = panel_bg } },
    { "OpenCodeQuotaLabel", { fg = label, bold = true } },
    { "OpenCodeQuotaTitle", { fg = accent, bold = true } },
    { "OpenCodeQuotaDim", { fg = dim } },
    { "OpenCodeQuotaBadgeOk", { fg = accent, bg = badge_bg, bold = true } },
    { "OpenCodeQuotaBadgeWarn", { fg = warn, bg = badge_bg, bold = true } },
    { "OpenCodeQuotaBadgeErr", { fg = err, bg = badge_bg, bold = true } },
    { "OpenCodeQuotaBarOk", { fg = accent } },
    { "OpenCodeQuotaBarWarn", { fg = warn } },
    { "OpenCodeQuotaBarErr", { fg = err } },
    { "OpenCodeQuotaBarBg", { fg = track } },
    { "OpenCodeQuotaTrack", { fg = track } },
  }
  for _, spec in ipairs(specs) do
    vim.api.nvim_set_hl(0, spec[1], spec[2])
  end
end

local function iso_to_epoch(s)
  local y, mo, d, h, mi, se = s:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then
    return nil
  end
  -- Treat the parsed fields as UTC, then shift by the local/UTC offset so the
  -- displayed time is the machine's local time.
  local utc = os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(se),
    isdst = false,
  })
  local now = os.time()
  local offset = os.difftime(os.time(os.date("!*t", now)), os.time(os.date("*t", now)))
  return utc - offset
end

local function to_epoch(ts)
  if type(ts) == "string" then
    local epoch = iso_to_epoch(ts)
    if epoch then
      return epoch
    end
    local n = tonumber(ts)
    if n then
      ts = n
    else
      return nil
    end
  end
  local n = tonumber(ts)
  if not n then
    return nil
  end
  if n > 1e12 then
    n = n / 1000
  end
  return n
end

local function fmt_reset(ts)
  if ts == nil then
    return nil
  end
  local epoch = to_epoch(ts)
  if not epoch then
    return "Resets " .. tostring(ts)
  end
  local diff = epoch - os.time()
  if diff <= 0 then
    return "Resets soon"
  end
  local secs = math.floor(diff)
  local mins = math.floor(secs / 60)
  local hours = math.floor(mins / 60)
  local days = math.floor(hours / 24)
  if days >= 1 then
    return ("Resets in %dd %dh"):format(days, hours % 24)
  elseif hours >= 1 then
    return ("Resets in %dh %dm"):format(hours, mins % 60)
  elseif mins >= 1 then
    return ("Resets in %dm"):format(mins)
  end
  return ("Resets in %ds"):format(secs)
end

local function field(tbl, names)
  for _, name in ipairs(names) do
    local value = tbl[name]
    if value ~= nil then
      return value
    end
  end
  return nil
end

local function label_of(tbl, fallback)
  local value = field(tbl, { "name", "window", "period", "label", "title", "type" })
  return value and tostring(value) or fallback
end

local function add_list(windows, list)
  if type(list) ~= "table" then
    return
  end

  local added = 0
  for _, item in ipairs(list) do
    if type(item) == "table" then
      windows[#windows + 1] = { label = label_of(item, "Window"), raw = item }
      added = added + 1
    end
  end

  if added == 0 then
    for key, item in pairs(list) do
      if type(item) == "table" then
        windows[#windows + 1] = { label = label_of(item, tostring(key)), raw = item }
      end
    end
  end
end

local function collect(data)
  local windows = {}
  if type(data) ~= "table" then
    return windows
  end

  -- The live endpoint wraps the three windows under a top-level `usage` key.
  if type(data.usage) == "table" then
    data = data.usage
  end

  for _, spec in ipairs(NAMED) do
    local item = data[spec.key]
    if type(item) == "table" then
      windows[#windows + 1] = { label = spec.label, raw = item }
    end
  end

  local list = data.windows or data.quotas or data.limits
  if type(list) == "table" then
    add_list(windows, list)
  elseif data[1] ~= nil then
    add_list(windows, data)
  end
  return windows
end

local function left_of(raw)
  local percent = tonumber(field(raw, PERCENT_FIELDS))
  if not percent then
    return nil
  end
  local left = 100 - percent
  if left < 0 then
    left = 0
  elseif left > 100 then
    left = 100
  end
  return left
end

local function tier(left)
  if left == nil then
    return "Bg"
  elseif left > 30 then
    return "Ok"
  elseif left >= 11 then
    return "Warn"
  end
  return "Err"
end

local function add_card(lines, marks, win)
  local raw = win.raw
  local left = left_of(raw)
  local reset = fmt_reset(field(raw, RESET_FIELDS))
  local level = tier(left)

  local badge_group = "OpenCodeQuotaBadge" .. level
  local bar_group = "OpenCodeQuotaBar" .. level
  if left == nil then
    badge_group = "OpenCodeQuotaDim"
    bar_group = "OpenCodeQuotaBarBg"
  end

  local label = win.label
  local badge = left and (" %d%% left "):format(math.floor(left + 0.5)) or " n/a "
  local gap = "  "
  local left_str = label .. gap .. badge
  local right = reset or ""
  local pad = WIDTH - #left_str - #right
  if pad < 1 then
    pad = 1
  end
  local header = left_str .. string.rep(" ", pad) .. right

  local row = #lines
  lines[#lines + 1] = PAD .. header
  marks[#marks + 1] = { row, PAD_LEN, PAD_LEN + #label, "OpenCodeQuotaLabel" }
  local badge_start = PAD_LEN + #label + #gap
  marks[#marks + 1] = { row, badge_start, badge_start + #badge, badge_group }
  if #right > 0 then
    marks[#marks + 1] = { row, PAD_LEN + #header - #right, PAD_LEN + #header, "OpenCodeQuotaDim" }
  end

  local fill = 0
  if left then
    fill = math.floor(left / 100 * WIDTH)
  end
  if fill < 0 then
    fill = 0
  elseif fill > WIDTH then
    fill = WIDTH
  end

  local bar_row = #lines
  lines[#lines + 1] = PAD .. string.rep(FILL, WIDTH)
  local filled_bytes = fill * #FILL
  local total_bytes = WIDTH * #FILL
  if filled_bytes > 0 then
    marks[#marks + 1] = { bar_row, PAD_LEN, PAD_LEN + filled_bytes, bar_group }
  end
  if filled_bytes < total_bytes then
    marks[#marks + 1] = { bar_row, PAD_LEN + filled_bytes, PAD_LEN + total_bytes, "OpenCodeQuotaBarBg" }
  end
end

local function plain_lines(windows, data)
  if #windows == 0 then
    return vim.split(vim.inspect(data), "\n", { plain = true })
  end

  local out = {}
  for i, win in ipairs(windows) do
    if i > 1 then
      out[#out + 1] = ""
    end
    local left = left_of(win.raw)
    local reset = fmt_reset(field(win.raw, RESET_FIELDS))
    local pct = left and ("%d%% left"):format(math.floor(left + 0.5)) or "n/a"
    local head = win.label .. "  " .. pct
    if reset then
      head = head .. "  " .. reset
    end
    out[#out + 1] = head
    local fill = left and math.floor(left / 100 * WIDTH) or 0
    if fill < 0 then
      fill = 0
    elseif fill > WIDTH then
      fill = WIDTH
    end
    out[#out + 1] = string.rep("#", fill) .. string.rep("-", WIDTH - fill)
  end
  return out
end

local function build(windows, data)
  local lines, marks = {}, {}
  if #windows == 0 then
    return vim.split(vim.inspect(data), "\n", { plain = true }), marks
  end
  lines[#lines + 1] = ""
  for i, win in ipairs(windows) do
    if i > 1 then
      lines[#lines + 1] = ""
    end
    add_card(lines, marks, win)
  end
  lines[#lines + 1] = ""
  return lines, marks
end

function M.render(data, err)
  if err then
    vim.notify("OpenCode Quota: " .. err, vim.log.levels.ERROR, { title = "OpenCode Quota" })
    return
  end

  local windows = collect(data)
  local lines, marks = build(windows, data)

  local snacks_ok, win = pcall(function()
    return _G.Snacks and _G.Snacks.win
  end)
  if not snacks_ok or not win then
    vim.notify(
      table.concat(plain_lines(windows, data), "\n"),
      vim.log.levels.INFO,
      { title = "OpenCode Quota" }
    )
    return
  end

  ensure_hl()

  local shown, obj = pcall(win, {
    text = lines,
    position = "left",
    width = WIDTH + 4,
    height = 0,
    border = "none",
    enter = true,
    fixbuf = true,
    keys = { q = "close" },
    wo = {
      winbar = "%#OpenCodeQuotaTitle#  OpenCode Quota ",
      winhighlight = "Normal:OpenCodeQuotaNormal,NormalNC:OpenCodeQuotaNormalNC,WinBar:OpenCodeQuotaTitle,WinBarNC:OpenCodeQuotaTitle",
    },
  })
  if not shown then
    vim.notify(
      table.concat(plain_lines(windows, data), "\n") .. "\n\n(snacks.win failed: " .. tostring(obj) .. ")",
      vim.log.levels.WARN,
      { title = "OpenCode Quota" }
    )
    return
  end

  pcall(function()
    local ns = vim.api.nvim_create_namespace("opencode-quota")
    for _, m in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(obj.buf, ns, m[1], m[2], {
        end_col = m[3],
        hl_group = m[4],
      })
    end
  end)

  return obj
end

return M
