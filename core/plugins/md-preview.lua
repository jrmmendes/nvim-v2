return {
  cmd = "MD",
  opts = {},
  build = "bash " .. vim.fn.stdpath("config") .. "/core/custom/md-preview/server/build.sh",
}
