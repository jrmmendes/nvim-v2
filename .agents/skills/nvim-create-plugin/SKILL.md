---
name: nvim-create-plugin
description: How to create local ("custom") plugins in this Neovim config — the core/custom + core/plugins layout, the Lua collector that wires their lazy.nvim specs, the minimal setup(opts) template, and the native OpenCode custom tool that scaffolds them. Use when the user wants to build their own plugin, replace a third-party plugin with a local one, or scaffold a new custom plugin.
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

External and local specs live side by side in `core/plugins/`; the collector
distinguishes them by the presence of a matching `core/custom/<name>/` tree.

## Collector

`core/config/custom.lua` globs `<config>/core/plugins/*.lua`, `dofile`s each one,
injects `dir = <config>/core/custom/<name>` and `name = <name>` when a matching
`core/custom/<name>/` tree exists, and returns the list of specs.
`core/config/lazy.lua` passes that list straight to `lazy.setup`:

```lua
spec = require("core.config.custom").collect(),
```

## Scaffolding

A native OpenCode custom tool lives at `.opencode/tools/new-custom-plugin.ts`
(tool name `new-custom-plugin`) and scaffolds the two files:

- Call it with `name` (required) and optionally `force = true`.
- `<name>` must match `[a-z][a-z0-9-]*`; the folder is the module name, so it is
  required as `require("<name>")`.
- Refuses to overwrite an existing `core/custom/<name>/` or
  `core/plugins/<name>.lua` unless `force = true`.
- Generates the spec (`event = { "VeryLazy" }, opts = {}`) and the minimal
  entrypoint below.

It imports `@opencode-ai/plugin`, declared in `.opencode/package.json`; OpenCode
runs `bun install` at startup, so the dependency resolves from
`.opencode/node_modules`. Never place a plain CLI script here — OpenCode imports
every `*.ts` in `.opencode/tools/` on startup.

If the tool is unavailable to the current agent, create the two files by hand
following the layout above.

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

## Async and UI

- Async callbacks run in a fast event context: schedule them onto the main loop
  before doing editor work (lazily requiring/creating UI, buffers, augroups). Use
  `vim.schedule_wrap` on the callback passed to `vim.system` / `vim.uv`.
- Touching the vim API in that context raises `E5560`; a failed lazy require
  there then surfaces as `loop or previous error loading module '...'`, which is
  misleading — look for the underlying fast-context error.
- Render floats with `Snacks.win` (see the UI foundation note in AGENTS.md) and
  guard it: capture the function, call it in `pcall`, and fall back to
  `vim.notify`.

```lua
function M.fetch(cb)
  -- curl/vim.uv complete in a fast event context; hop to the main loop before
  -- any editor work (e.g. lazily loading Snacks.win, which creates augroups).
  cb = vim.schedule_wrap(cb)
  ...
end
```

## Procedure

1. Read `AGENTS.md`, `core/config/custom.lua` and `core/config/lazy.lua`.
2. Scaffold with the `new-custom-plugin` tool, or create the two files by hand
   following the layout above.
3. Implement the plugin under `core/custom/<name>/lua/<name>/`.
4. Validate: `nvim --headless "+lua vim.cmd('qa')"` exits 0, and the plugin shows
   up in `:Lazy`. Exercise the real async path (do not only stub `Snacks.win`) and,
   if the plugin renders UI, run its callback from a `vim.uv` timer callback to
   confirm no `E5560`.
5. Restart Neovim (or `:Lazy reload`) for the collector to pick up new files.

External plugins use the same `core/plugins/<concern>.lua` location (no separate
tree) — see the `nvim-add-plugin` skill.
