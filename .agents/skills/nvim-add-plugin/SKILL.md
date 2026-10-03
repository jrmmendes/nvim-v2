---
name: nvim-add-plugin
description: How to add, change or configure plugins and plugin stacks in this lazy.nvim Neovim config (new concern file in core/plugins, spec fields, lazy-loading). Use when the user wants to install a plugin, change a plugin's options, add a dependency, or wire up a new plugin stack.
compatibility: opencode
---

# Adding and configuring plugins (lazy.nvim)

This repo loads every spec in `core/plugins/` through a small collector:

```lua
-- core/config/lazy.lua
require("lazy").setup({ spec = require("core.config.custom").collect(), ... })
```

`core/config/custom.lua` globs `core/plugins/*.lua`, `dofile`s each one, injects
`dir`/`name` into specs that have a matching `core/custom/<name>/` tree, and
returns the list. This replaces lazy's `import = "plugins"` so external and local
specs can live flat in `core/plugins/` (no `lua/plugins/` tree).

So **adding a plugin = adding a file** `core/plugins/<concern>.lua` that returns a
lazy.nvim spec. Never register plugins anywhere else (`init.lua` stays clean).

## Procedure

1. Read `AGENTS.md` and 2–3 neighbouring files (e.g. `core/plugins/snacks.lua`,
   `core/plugins/conform.lua`) to match style.
2. Decide the concern name. One concern per file: `lsp.lua`, `conform.lua`,
   `gitsigns.lua`, `codecompanion.lua`, ...
3. If the concern already has a file, **edit that file** instead of creating a
   new one.
4. Write the spec, preferring `opts` over a `config` function.
5. Validate: `nvim --headless "+lua vim.cmd('qa')"` exits 0. Then `:Lazy` /
   `:Lazy sync` to install and check for errors.

## Spec shape

Prefer tables and `opts`. Use `config = function()` only for real setup logic.

```lua
return {
  "author/plugin.nvim",
  dependencies = { "other/dep.nvim" },
  event = { "BufReadPre", "BufNewFile" }, -- or ft = {...}, cmd = {...}
  keys = {
    { "<leader>x", function() require("plugin").action() end, desc = "Do X" },
  },
  opts = {
    option = true,
  },
}
```

Simple one-liner concerns can return a bare repo string:

```lua
return {
  "tpope/vim-fugitive",
}
```

## Fields that matter here

- `opts` — preferred. lazy.nvim calls `require(plugin).setup(opts)`.
  Use `opts_extend` when merging list fields (see `core/plugins/completion.lua`).
- `config = function()` — only when setup is not a plain `setup(opts)` call
  (see `core/plugins/lsp.lua`, `core/plugins/dap.lua`).
- `dependencies` — other plugins that must load first.
- `event` / `ft` / `cmd` — lazy-load triggers. Prefer these over eager loading.
- `keys` — plugin keymaps, lazy-loadable. Use `desc` on every entry.
- `priority` — raise for colorschemes/UI hubs (e.g. `1000`).
- `lazy = false` — only when the plugin must load at startup (colorscheme,
  snacks UI hub, treesitter, lspconfig in this repo).
- `build` — post-install command (e.g. `build = ":TSUpdate"`).

## Common patterns in this repo

- UI hub: `folke/snacks.nvim` is `priority = 1000, lazy = false` and owns many
  keymaps via its `keys` table (`core/plugins/snacks.lua`).
- Colorscheme: `priority = 1000, lazy = false` with a `config` that calls
  `vim.cmd.colorscheme("gruvbox")` (`core/plugins/colorscheme.lua`).
- Load-on-event formatters: `conform.nvim` uses `event = { "BufWritePre" }` and
  a `keys` entry (`core/plugins/conform.lua`).
- Mason/LSP wiring is its own concern (`core/plugins/lsp.lua`) — for anything
  LSP-related, use the `nvim-lsp` skill instead.

## After adding

- Remind the user that new keymaps/plugins need a Neovim restart (or `:Lazy reload`).
- Never edit `lazy-lock.json` by hand; let lazy update it via `:Lazy sync`.
