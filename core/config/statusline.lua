-- Modern powerline-style statusline (global, laststatus = 3).

local M = {}

local C = {
  bg = "#3c3836", -- gruvbox bg1
  bg_deep = "#282828",
  fg = "#ebdbb2",
  fg0 = "#fbf1c7",
  gray = "#a89984",
  gray_dim = "#7c6f64",
  red = "#fb4934",
  green = "#b8bb26",
  yellow = "#fabd2f",
  orange = "#fe8019",
  blue = "#83a598",
  purple = "#d3869b",
  aqua = "#8ec07c",
}

local ARROW, LARROW, DOT = "", "", ""
local BLOCK = string.char(22) -- ^V: visual/select block mode key

local modes = {
  n = { "NORMAL", C.green },
  ni = { "NORMAL", C.green },
  v = { "VISUAL", C.purple },
  V = { "V-LINE", C.purple },
  [BLOCK] = { "V-BLOCK", C.purple },
  s = { "SELECT", C.purple },
  S = { "S-LINE", C.purple },
  i = { "INSERT", C.blue },
  ic = { "INSERT", C.blue },
  R = { "REPLACE", C.red },
  c = { "COMMAND", C.yellow },
  cv = { "COMMAND", C.yellow },
  ce = { "COMMAND", C.yellow },
  t = { "TERMINAL", C.aqua },
}

local function id(mode_name) return mode_name:gsub("-", "") end

local function esc(s) return (s:gsub("%%", "%%")) end

local function seg(hl, text) return "%#" .. hl .. "#" .. esc(text) end

local function icon_for(name, buf)
  local ok, mini = pcall(require, "mini.icons")
  if not ok then return "", "SLFileIcon" end
  local glyph
  pcall(function() glyph = mini.get("file", name) end)
  if not glyph then pcall(function() glyph = mini.get("filetype", vim.bo[buf].ft) end) end
  return glyph or "", "SLFileIcon"
end

local severity = {
  { n = 1, icon = "", hl = "SLError", color = C.red, bold = true },
  { n = 2, icon = "", hl = "SLWarn", color = C.yellow },
  { n = 3, icon = "", hl = "SLInfo", color = C.blue },
  { n = 4, icon = "", hl = "SLHint", color = C.gray },
}

local function hl_setup()
  local function set(name, o) vim.api.nvim_set_hl(0, name, o) end
  set("SLFile", { bg = C.bg, fg = C.fg0, bold = true })
  set("SLFileIcon", { bg = C.bg, fg = C.yellow })
  set("SLFlags", { bg = C.bg, fg = C.orange, bold = true })
  set("SLSep", { bg = C.bg, fg = C.gray_dim })
  set("SLGit", { bg = C.bg, fg = C.aqua })
  set("SLGitAdd", { bg = C.bg, fg = C.green })
  set("SLGitDel", { bg = C.bg, fg = C.red })
  set("SLBranch", { bg = C.bg, fg = C.aqua })
  set("SLSearch", { bg = C.bg, fg = C.purple })
  set("SLLsp", { bg = C.bg, fg = C.aqua })
  set("SLPos", { bg = C.bg, fg = C.fg })
  set("SLProgress", { bg = C.bg, fg = C.yellow, bold = true })
  set("SLTime", { bg = C.bg, fg = C.gray })
  set("SLMacro", { bg = C.red, fg = C.bg_deep, bold = true })
  set("SLArrow_MACRO", { bg = C.bg, fg = C.red })
  for _, s in ipairs(severity) do
    set(s.hl, { bg = C.bg, fg = s.color, bold = s.bold or false })
  end
  for _, m in pairs(modes) do
    local i = id(m[1])
    set("SLMode_" .. i, { bg = m[2], fg = C.bg_deep, bold = true })
    set("SLArrow_" .. i, { bg = C.bg, fg = m[2] })
  end
end

function M.render()
  local mode = modes[vim.api.nvim_get_mode().mode] or modes.n
  local mid = id(mode[1])
  local buf = vim.api.nvim_win_get_buf(0)

  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
  if name == "" then name = "[No Name]" end
  name = vim.fn.pathshorten(name)

  local glyph, ihl = icon_for(name, buf)
  local flags = table.concat({
    vim.bo[buf].modified and " " or "",
    vim.bo[buf].readonly and " " or "",
    vim.bo[buf].buftype == "terminal" and " term" or "",
  })

  local left = table.concat({
    "%#SLMode_" .. mid .. "#  " .. mode[1] .. " ",
    "%#SLArrow_" .. mid .. "#" .. ARROW,
    "%#" .. ihl .. "#" .. glyph,
    seg("SLFile", " " .. name),
    seg("SLFlags", flags),
    seg("SLSep", "  " .. DOT),
  })

  local counts = vim.diagnostic.count(buf)
  for _, s in ipairs(severity) do
    local n = counts[s.n]
    if n and n > 0 then left = left .. seg(s.hl, " " .. s.icon .. n) end
  end

  local macro = vim.fn.reg_recording()
  if macro ~= "" then
    left = left .. "%#SLArrow_MACRO#" .. LARROW .. "%#SLMacro#  " .. macro .. " "
  end

  local right = {}
  local gs = vim.b[buf].gitsigns_status_dict
  if gs and gs.head then
    right[#right + 1] = seg("SLSep", DOT .. "  ")
    right[#right + 1] = seg("SLBranch", "  " .. gs.head)
    if (gs.added or 0) > 0 then right[#right + 1] = seg("SLGitAdd", " +" .. gs.added) end
    if (gs.removed or 0) > 0 then right[#right + 1] = seg("SLGitDel", " -" .. gs.removed) end
  end

  if vim.v.hlsearch ~= 0 then
    local ok, sc = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 100 })
    if ok and sc and sc.total and sc.total > 0 then
      right[#right + 1] = seg("SLSearch", "  " .. sc.current .. "/" .. sc.total)
    end
  end

  if next(vim.lsp.get_clients({ bufnr = buf })) then
    right[#right + 1] = seg("SLLsp", "  ")
  end

  local mode_str = vim.api.nvim_get_mode().mode
  if mode_str == "v" or mode_str == "V" or mode_str == BLOCK then
    local words = vim.fn.wordcount().visual_words
    if words then right[#right + 1] = seg("SLPos", "  " .. words .. " sel") end
  end

  right[#right + 1] = seg("SLSep", "  " .. DOT .. "  ")
  right[#right + 1] = seg("SLProgress", "%p%%")
  right[#right + 1] = seg("SLSep", "  " .. DOT .. "  ")
  right[#right + 1] = seg("SLPos", " %l:%c ")
  right[#right + 1] = seg("SLSep", "  " .. DOT .. "  ")
  right[#right + 1] = seg("SLTime", " " .. os.date("%H:%M"))

  return "%<" .. left .. "%=" .. table.concat(right)
end

function M.setup()
  hl_setup()
  vim.go.statusline = "%{%v:lua.require'core.config.statusline'.render()%}"
  vim.api.nvim_create_autocmd("ColorScheme", { callback = hl_setup })
  vim.defer_fn(function()
    local timer = assert(vim.uv.new_timer())
    timer:start(1000, 1000, vim.schedule_wrap(function()
      if vim.go.laststatus > 0 then pcall(vim.cmd, "redrawstatus") end
    end))
  end, 1000)
end

return M
