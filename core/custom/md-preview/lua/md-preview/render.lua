local M = {}

local escape_entities = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
}

local function escape(text)
  return (text:gsub("[&<>\"]", escape_entities))
end

local function escape_attr(text)
  return (text:gsub("[&<>\"']", function(ch)
    return escape_entities[ch] or "&#39;"
  end))
end

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function get_text(node, src)
  return vim.treesitter.get_node_text(node, src)
end

local function find_child(node, want)
  for child in node:iter_children() do
    if child:type() == want then
      return child
    end
  end
  return nil
end

local function find_child_prefix(node, prefix)
  for child in node:iter_children() do
    if child:type():sub(1, #prefix) == prefix then
      return child
    end
  end
  return nil
end

local function plain_replace(text, needle)
  if needle == "" then
    return text
  end
  local out, i = {}, 1
  while true do
    local s, e = text:find(needle, i, true)
    if not s then
      out[#out + 1] = text:sub(i)
      break
    end
    out[#out + 1] = text:sub(i, s - 1)
    i = e + 1
  end
  return table.concat(out)
end

local function collect_markers(node, src)
  local markers = {}
  local function rec(n)
    for child in n:iter_children() do
      if child:type() == "block_continuation" then
        local text = get_text(child, src)
        if text ~= "" then
          markers[#markers + 1] = text
        end
      end
      rec(child)
    end
  end
  rec(node)
  return markers
end

local function line_offsets(src)
  local offsets = { 0 }
  local pos = 0
  while true do
    local nl = src:find("\n", pos + 1, true)
    if not nl then
      break
    end
    offsets[#offsets + 1] = nl
    pos = nl
  end
  return offsets
end

local function parse_inline(text)
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown_inline")
  if not ok or not parser then
    return nil
  end
  local ok2, trees = pcall(function()
    return parser:parse()
  end)
  if not ok2 or not trees or not trees[1] then
    return nil
  end
  return trees[1]:root(), text
end

local render_inline

local function render_inline_into(node, src, out)
  local offsets = line_offsets(src)
  local cursor = 0
  local function byte_of(row, col)
    return (offsets[row + 1] or 0) + col
  end

  for child in node:iter_children() do
    local srow, scol, erow, ecol = child:range()
    local s, e = byte_of(srow, scol), byte_of(erow, ecol)
    if s > cursor then
      out[#out + 1] = escape(src:sub(cursor + 1, s))
    end

    local ctype = child:type()
    if ctype == "emphasis" or ctype == "strong_emphasis" or ctype == "strikethrough" then
      local tag = ctype == "emphasis" and "em" or (ctype == "strong_emphasis" and "strong" or "del")
      local n = ctype == "emphasis" and 1 or 2
      local raw = get_text(child, src)
      local inner = raw
      if #raw > 2 * n then
        inner = raw:sub(n + 1, #raw - n)
      end
      out[#out + 1] = "<" .. tag .. ">" .. render_inline(inner) .. "</" .. tag .. ">"
    elseif ctype == "code_span" then
      local raw = get_text(child, src)
      local inner = raw:gsub("^`+", ""):gsub("`+$", "")
      out[#out + 1] = "<code>" .. escape(inner) .. "</code>"
    elseif ctype == "inline_link" then
      local dest = find_child(child, "link_destination")
      local label = find_child(child, "link_text")
      local href = dest and get_text(dest, src) or ""
      local body = label and render_inline(get_text(label, src)) or escape(href)
      out[#out + 1] = '<a href="' .. escape_attr(href) .. '">' .. body .. "</a>"
    elseif
      ctype == "full_reference_link"
      or ctype == "collapsed_reference_link"
      or ctype == "shortcut_link"
    then
      local raw = get_text(child, src)
      local label = raw:gsub("^%[", ""):gsub("%].*$", "")
      out[#out + 1] = render_inline(label)
    elseif ctype == "image" then
      local dest = find_child(child, "link_destination")
      local alt = find_child(child, "image_description")
      local href = dest and get_text(dest, src) or ""
      if href ~= "" and not href:match("^%a[%w+.-]*:") and not href:match("^//") then
        href = "/img/" .. href
      end
      out[#out + 1] = '<img src="'
        .. escape_attr(href)
        .. '" alt="'
        .. escape_attr(alt and get_text(alt, src) or "")
        .. '">'
    elseif ctype == "uri_autolink" or ctype == "email_autolink" then
      local raw = get_text(child, src)
      local inner = raw:gsub("^<", ""):gsub(">$", "")
      local href = ctype == "email_autolink" and ("mailto:" .. inner) or inner
      out[#out + 1] = '<a href="' .. escape_attr(href) .. '">' .. escape(inner) .. "</a>"
    elseif ctype == "hard_line_break" then
      out[#out + 1] = "<br>"
    elseif ctype == "backslash_escape" then
      out[#out + 1] = escape((get_text(child, src):gsub("^\\", "")))
    elseif ctype == "entity_reference" or ctype == "numeric_character_reference" then
      out[#out + 1] = get_text(child, src)
    elseif ctype == "html_tag" then
      out[#out + 1] = get_text(child, src)
    elseif child:named() then
      render_inline_into(child, src, out)
    else
      out[#out + 1] = escape(get_text(child, src))
    end

    if e > cursor then
      cursor = e
    end
  end

  if cursor < #src then
    out[#out + 1] = escape(src:sub(cursor + 1))
  end
end

render_inline = function(text)
  if text == nil or text == "" then
    return ""
  end
  local root, src = parse_inline(text)
  if not root then
    return escape(text)
  end
  local out = {}
  render_inline_into(root, src, out)
  return table.concat(out)
end

local render_blocks
local inline_text
local render_list

local function render_list_item(item, src, out)
  local checked = find_child(item, "task_list_marker_checked")
  local unchecked = find_child(item, "task_list_marker_unchecked")
  out[#out + 1] = "<li>"
  if checked or unchecked then
    out[#out + 1] = checked and '<input type="checkbox" checked disabled> '
      or '<input type="checkbox" disabled> '
  end
  for child in item:iter_children() do
    local ctype = child:type()
    if ctype == "paragraph" then
      local text = inline_text(child, src)
      if text then
        out[#out + 1] = render_inline(text)
      end
    elseif ctype == "list" then
      render_list(child, src, out)
    elseif ctype == "fenced_code_block" or ctype == "indented_code_block" or ctype == "block_quote" or ctype == "pipe_table" or ctype == "thematic_break" then
      render_blocks(child, src, out)
    end
  end
  out[#out + 1] = "</li>\n"
end

render_list = function(list, src, out)
  local first_item = find_child(list, "list_item")
  local ordered = false
  if first_item then
    for child in first_item:iter_children() do
      local t = child:type()
      if t == "list_marker_dot" or t == "list_marker_parenthesis" then
        ordered = true
        break
      end
    end
  end
  local tag = ordered and "ol" or "ul"
  out[#out + 1] = "<" .. tag .. ">\n"
  for child in list:iter_children() do
    if child:type() == "list_item" then
      render_list_item(child, src, out)
    end
  end
  out[#out + 1] = "</" .. tag .. ">\n"
end

local function render_table(node, src, out)
  local header = find_child(node, "pipe_table_header")
  out[#out + 1] = "<table>\n"
  if header then
    out[#out + 1] = "<thead><tr>"
    for cell in header:iter_children() do
      if cell:type() == "pipe_table_cell" then
        out[#out + 1] = "<th>" .. render_inline(trim(get_text(cell, src))) .. "</th>"
      end
    end
    out[#out + 1] = "</tr></thead>\n"
  end
  out[#out + 1] = "<tbody>\n"
  for row in node:iter_children() do
    if row:type() == "pipe_table_row" then
      out[#out + 1] = "<tr>"
      for cell in row:iter_children() do
        if cell:type() == "pipe_table_cell" then
          out[#out + 1] = "<td>" .. render_inline(trim(get_text(cell, src))) .. "</td>"
        end
      end
      out[#out + 1] = "</tr>\n"
    end
  end
  out[#out + 1] = "</tbody>\n</table>\n"
end

local function heading_level(node)
  local marker = find_child_prefix(node, "atx_h")
  if marker then
    local level = marker:type():match("atx_h(%d)")
    if level then
      return tonumber(level)
    end
  end
  local underline = find_child_prefix(node, "setext_h")
  if underline then
    return underline:type():match("setext_h(%d)") and tonumber(underline:type():match("setext_h(%d)")) or 1
  end
  return 1
end

inline_text = function(node, src)
  local inline = find_child(node, "inline")
  if not inline then
    local paragraph = find_child(node, "paragraph")
    inline = paragraph and find_child(paragraph, "inline") or nil
  end
  if not inline then
    return nil
  end
  local text = get_text(inline, src)
  for _, marker in ipairs(collect_markers(node, src)) do
    text = plain_replace(text, marker)
  end
  return text
end

render_blocks = function(node, src, out)
  for child in node:iter_children() do
    local ctype = child:type()
    if ctype == "document" or ctype == "section" then
      render_blocks(child, src, out)
    elseif ctype == "atx_heading" or ctype == "setext_heading" then
      local level = heading_level(child)
      local text = inline_text(child, src)
      out[#out + 1] = ("<h%d>%s</h%d>\n"):format(level, text and render_inline(text) or "", level)
    elseif ctype == "paragraph" then
      local text = inline_text(child, src)
      if text then
        out[#out + 1] = "<p>" .. render_inline(text) .. "</p>\n"
      end
    elseif ctype == "block_quote" then
      out[#out + 1] = "<blockquote>\n"
      render_blocks(child, src, out)
      out[#out + 1] = "</blockquote>\n"
    elseif ctype == "list" then
      render_list(child, src, out)
    elseif ctype == "fenced_code_block" then
      local info = find_child(child, "info_string")
      local lang = ""
      if info then
        local language = find_child(info, "language")
        lang = language and get_text(language, src) or (get_text(info, src):match("^(%S+)") or "")
      end
      local content = find_child(child, "code_fence_content")
      local code = content and get_text(content, src) or ""
      code = code:gsub("\n$", "")
      local class = lang ~= "" and (' class="language-' .. escape_attr(lang) .. '"') or ""
      out[#out + 1] = "<pre><code" .. class .. ">" .. escape(code) .. "</code></pre>\n"
    elseif ctype == "indented_code_block" then
      local code = get_text(child, src):gsub("^\n", ""):gsub("\n$", "")
      code = code:gsub("^    ", ""):gsub("\n    ", "\n"):gsub("\n\t", "\n"):gsub("^\t", "")
      out[#out + 1] = "<pre><code>" .. escape(code) .. "</code></pre>\n"
    elseif ctype == "pipe_table" then
      render_table(child, src, out)
    elseif ctype == "thematic_break" then
      out[#out + 1] = "<hr>\n"
    elseif ctype == "html_block" then
      out[#out + 1] = get_text(child, src)
    end
  end
end

local CSS = [[
:root {
  color-scheme: light dark;
}
* {
  box-sizing: border-box;
}
body {
  margin: 0 auto;
  max-width: 46rem;
  padding: 2.5rem 1.25rem 6rem;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  font-size: 17px;
  line-height: 1.65;
  color: #24292f;
  background: #ffffff;
  word-wrap: break-word;
}
h1, h2, h3, h4, h5, h6 {
  margin: 1.8em 0 0.6em;
  line-height: 1.25;
  font-weight: 600;
}
h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid #d0d7de; }
h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid #d0d7de; }
h3 { font-size: 1.25em; }
p { margin: 0 0 1em; }
a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }
code {
  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
  font-size: 0.88em;
  background: #f0f1f3;
  padding: 0.15em 0.35em;
  border-radius: 5px;
}
pre {
  background: #f6f8fa;
  border: 1px solid #e1e4e8;
  border-radius: 6px;
  padding: 1em;
  overflow: auto;
}
pre code { background: none; padding: 0; font-size: 0.85em; }
blockquote {
  margin: 0 0 1em;
  padding: 0 1em;
  color: #57606a;
  border-left: 0.25em solid #d0d7de;
}
ul, ol { margin: 0 0 1em; padding-left: 2em; }
li { margin: 0.25em 0; }
li input[type="checkbox"] { margin-right: 0.4em; }
table { border-collapse: collapse; margin: 0 0 1em; display: block; overflow: auto; }
th, td { border: 1px solid #d0d7de; padding: 0.4em 0.75em; }
th { background: #f6f8fa; font-weight: 600; }
img { max-width: 100%; }
hr { height: 1px; border: 0; background: #d0d7de; margin: 2em 0; }
del { color: #6e7781; }
@media (prefers-color-scheme: dark) {
  body { color: #c9d1d9; background: #0d1117; }
  h1, h2 { border-bottom-color: #30363d; }
  a { color: #58a6ff; }
  code { background: #161b22; }
  pre { background: #161b22; border-color: #30363d; }
  blockquote { color: #8b949e; border-left-color: #30363d; }
  th, td { border-color: #30363d; }
  th { background: #161b22; }
  hr { background: #30363d; }
  del { color: #8b949e; }
}
]]

local LIVE_RELOAD = [[
(function () {
  var current = null;
  function poll() {
    fetch(location.pathname.replace(/\/$/, "") + "/version")
      .then(function (r) { return r.text(); })
      .then(function (v) {
        if (current === null) { current = v; }
        else if (v !== current) { current = v; location.reload(); }
      })
      .catch(function () {});
  }
  setInterval(poll, 700);
})();
]]

function M.to_html(text)
  if vim.in_fast_event() then
    return "<p>" .. escape(text) .. "</p>"
  end
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown")
  if not ok or not parser then
    return "<p>" .. escape(text) .. "</p>"
  end
  local ok2, trees = pcall(function()
    return parser:parse()
  end)
  if not ok2 or not trees or not trees[1] then
    return "<p>" .. escape(text) .. "</p>"
  end
  local out = {}
  render_blocks(trees[1]:root(), text, out)
  return table.concat(out)
end

function M.page(title, body)
  return table.concat({
    "<!DOCTYPE html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    "<title>" .. escape(title) .. "</title>",
    "<style>",
    CSS,
    "</style>",
    "</head>",
    "<body>",
    body,
    "<script>",
    LIVE_RELOAD,
    "</script>",
    "</body>",
    "</html>",
  }, "\n")
end

return M
