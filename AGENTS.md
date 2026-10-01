# AGENTS.md — Neovim config (Mendes' v3)

Always-active guidance for coding agents (OpenCode) working in this repository.
Read this before touching any file. Detailed, task-specific procedures live in
the skills under `.agents/skills/` and are loaded on demand.

## What this repo is

A modern, modular Neovim configuration targeting **Neovim >= 0.12** and its
native APIs (`vim.lsp.config`, `vim.lsp.enable`, `vim.snippet`, `vim.uv`), using
**lazy.nvim**. Lua only. README is in English; keep new docs in English.

## Architecture

- `init.lua` — orchestrator. Requires, in order: `config.options`,
  `config.keymaps`, `config.autocmds`, `config.statusline` (`.setup()`), then
  `config.lazy`. Do not add plugin code here.
- `lua/config/` — cross-cutting config:
  - `options.lua` — single source of truth for `vim.opt` / `vim.g`. Leader keys
    (`mapleader = " "`, `maplocalleader = "\\"`) are defined here, before lazy.
  - `keymaps.lua` — global keymaps only.
  - `autocmds.lua` — global autocmds.
  - `statusline.lua` — custom powerline-style statusline (used because
    `laststatus = 3` and snacks' statusline is disabled).
  - `lazy.lua` — lazy.nvim bootstrap + `setup({ spec = { { import = "plugins" } } })`.
- `lua/plugins/` — **one file per concern**, auto-imported by the `import = "plugins"`
  glob. Adding a file here is enough; never register plugins manually elsewhere.
- `core/` — local ("custom") plugins. `core/custom/<name>/` is the pure plugin
  tree; `core/plugins/<name>.lua` holds its lazy.nvim spec. Not auto-imported:
  `lua/config/custom.lua` collects the specs and injects `dir`/`name`, and
  `lua/config/lazy.lua` merges them with `import = "plugins"`.
- `lazy-lock.json` — generated lockfile. `lazy-lock.json.bak` is a manual backup.
- `lua/config/statusline.lua`, `lua/plugins/*.lua` — return a lazy.nvim spec
  (a table, or a function returning one).

## Conventions

- One concern per file in `lua/plugins/`; name it after the concern (e.g.
  `lsp.lua`, `conform.lua`, `snacks.lua`).
- Plugin specs follow lazy.nvim: `dependencies`, `opts` (preferred over a
  `config` function when possible), `keys`, `cmd`, `event`, `ft`, `priority`,
  `lazy`. Use `opts = {}` for simple config and `config = function()` only when
  setup logic is required.
- Prefer **native Neovim 0.12 APIs** over legacy plugins/APIs:
  `vim.lsp.config` / `vim.lsp.enable`, `vim.snippet`, `vim.uv`.
- Options go in `lua/config/options.lua`; keymaps in `lua/config/keymaps.lua`
  (global) or a plugin's `keys` (plugin-specific, lazy-loadable).
- Buffer-local keymaps belong on `LspAttach` (see `lua/plugins/lsp.lua`), not in
  the global keymaps file.
- Lua style: 2-space indent, double quotes, no trailing whitespace, no comments
  unless they add real value. Match surrounding files.

## Async and UI

- Async callbacks must return to the main loop before touching the editor. Wrap
  the callback of `vim.system` / `vim.uv` (timers, sockets, ...) in `vim.schedule`
  or `vim.schedule_wrap`. Doing editor work (buffers/windows/augroups,
  lazy-requiring a UI module) in a fast event context raises
  `E5560: ... must not be called in a fast event context` — and, once a lazy
  require has failed there, later attempts report the misleading
  `loop or previous error loading module '<mod>'`.
- Dock custom UIs on `snacks` (`Snacks.win`) and always call it inside `pcall`
  with a `vim.notify` fallback, so a UI failure degrades to a message instead of
  aborting the command. The UI foundation strategy is
  `.plans/2026-10-01-1400-ui-fundacao-draft.md`.
- When integrating an external API, validate the parser against a real response,
  not only a headless load — payload shape drifts (e.g. a top-level `usage`
  wrapper, or `resetsAt` as an ISO-8601 string rather than an epoch number).
- UI/async code must be tested through its real path. Stubbing or overriding a
  lazily-required module (e.g. setting `_G.Snacks.win`) hides require-path
  failures; also exercise the callback from a fast event context (a `vim.uv`
  timer callback) to catch `E5560`.

## Guardrails

- **Never hand-edit `lazy-lock.json`.** Use `:Lazy` (sync/update) instead.
- Do not commit generated/vendored artifacts (`plugin/`, `node_modules`, tags).
- Do not move leader-key definitions out of `options.lua`; they must load before
  `lazy.lua`.
- Keep `init.lua` free of plugin configuration.
- If a skill's instructions ever disagree with the code, **the code is the
  truth** — read the relevant files before acting and follow the code.
- Never perform editor work in a fast event context; schedule the callback to
  the main loop first (see "Async and UI").
- Before declaring a task done, validate: `nvim --headless "+lua vim.cmd('qa')"`
  must exit cleanly, and check `:checkhealth` / `:Lazy` when relevant. Lua syntax
  can be checked with `luajit -bl`/`nvim --headless` as appropriate.

## Routing map — pick the matching skill

| Task                                                | Skill                   |
| --------------------------------------------------- | ----------------------- |
| Add/change/configure a plugin or plugin stack       | `nvim-add-plugin`       |
| Create/scaffold a local custom plugin (`core/`)     | `nvim-create-plugin`    |
| Add/change keybinds (global or plugin/buffer-local) | `nvim-keymaps`          |
| Configure LSP servers, mason, install servers       | `nvim-lsp`              |
| Change options or autocmds                          | `nvim-options-autocmds` |
| Debug/reproduce a config error or broken behavior   | `nvim-debug`            |
| Answer questions about the current config (read-only)| `nvim-config-info`      |

## Delegation protocol

`Build:Nvim` is a thin orchestrator. Do not burn its context doing the work
inline:

1. Classify the request against the routing map.
2. Load/select the matching skill (or instruct the subagent to load it).
3. Delegate execution to a **generic subagent** via the `task` tool, passing:
   the chosen skill name, the exact files to read, and a precise brief.
4. Validate the subagent's result (diff, and the headless load command).
5. Report back to the user, including the files changed and how it was verified.

Delegating is the default. Only handle a request inline when it is a trivial
read-only answer, and prefer `nvim-config-info` even then.
