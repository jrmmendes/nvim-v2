local M = {}

function M.base_root(path)
  local ok, git = pcall(vim.fs.root, path, ".git")
  if ok and git then
    return git
  end
  local home = vim.fn.expand("~")
  if path == home or path:sub(1, #home + 1) == home .. "/" then
    return home
  end
  return "/"
end

function M.slug_for(path)
  local abs = vim.fn.fnamemodify(path, ":p")
  abs = abs:gsub("/+$", "")
  if abs == "" then
    abs = "/"
  end

  local root = M.base_root(abs)
  local rel = abs:sub(#root + 1)
  rel = rel:gsub("%.md$", "")
  rel = rel:gsub("%s+", "-")
  rel = rel:gsub("[^%w/._-]", "-")
  rel = rel:gsub("/+", "/")
  rel = rel:gsub("^/+", "")

  if rel == "" then
    rel = vim.fn.fnamemodify(abs, ":t")
  end
  return rel
end

return M
