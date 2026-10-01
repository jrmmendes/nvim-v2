---
name: nvim-create-plugin
description: How to create local ("custom") plugins in this Neovim config — the core/custom + core/plugins layout, the Lua collector that wires their lazy.nvim specs, the minimal setup(opts) template, and the Node bootstrap that scaffolds them. Use when the user wants to build their own plugin, replace a third-party plugin with a local one, or scaffold a new custom plugin.
compatibility: opencode
---

# Creating local ("custom") plugins

This config can host in-tree plugins that coexist with external lazy.nvim
plugins and can later be extracted into standalone repositories.

## Layout

- `core/custom/<name>/` — the **pure plugin tree** (ecosystem layout: entrypoint
  at `lua/<name>/init.lua`, `M.setup(opts)` idempotent, `return M`). Keep it
  free of `plugin/`, `doc/` and globals.
- `core/plugins/<name>.lua` — the **lazy.nvim spec**, identical in shape to an
  external plugin spec, except it carries **no path**: the collector injects
  `dir` and `name`.

Specs under `core/plugins/` are **not** auto-imported by `import = "plugins"`
(they live outside `lua/`), so a dedicated collector handles them.

## Collector

`lua/config/custom.lua` globs `<config>/core/plugins/*.lua`, `dofile`s each one,
injects `dir = <config>/core/custom/<basename>` and `name = <basename>` when
absent, and returns the list of specs. `lua/config/lazy.lua` merges them next to
`{ import = "plugins" }`:

```lua
spec = vim.list_extend({ { import = "plugins" } }, require("config.custom").collect()),
```

## Scaffolding

Requires **Node 23+** (native TypeScript type-stripping; no build step):

```bash
node .opencode/tools/new-custom-plugin.ts <name>
```

- `<name>` must match `[a-z][a-z0-9-]*`; the folder is the module name, so it is
  required as `require("<name>")`.
- Refuses to overwrite an existing `core/custom/<name>/` or
  `core/plugins/<name>.lua` unless `--force` is passed.
- Generates the spec (`event = { "VeryLazy" }, opts = {}`) and the minimal
  entrypoint below.

## Minimal template

```lua
local M = {}

local configured = false

function M.setup(opts)
  if configured then
    return
  end
  configured = true
  opts = opts or {}
end

return M
```

No `plugin/`, `doc/` or global namespace. UI work should follow the foundation
strategy in `.plans/2026-10-01-1400-ui-fundacao-draft.md` (snacks + nui) rather
than inventing its own subsystem.

## Procedure

1. Read `AGENTS.md`, `lua/config/custom.lua` and `lua/config/lazy.lua`.
2. Scaffold with the bootstrap, or create the two files by hand following the
   layout above.
3. Implement the plugin under `core/custom/<name>/lua/<name>/`.
4. Validate: `nvim --headless "+lua vim.cmd('qa')"` exits 0, and the plugin shows
   up in `:Lazy`.
5. Restart Neovim (or `:Lazy reload`) for the collector to pick up new files.

External plugins still use `lua/plugins/<concern>.lua` — see the
`nvim-add-plugin` skill.
