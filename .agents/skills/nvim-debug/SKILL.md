---
name: nvim-debug
description: How to investigate and reproduce broken behavior or errors in this Neovim config — startup errors, messages/LspLog, headless reproduction, health checks, Lazy state, bisecting a broken change. Use when the user reports an error, a plugin not loading, or behavior that used to work and now doesn't.
compatibility: opencode
---

# Debugging the Neovim config

Goal: produce a **minimal reproduction**, identify the offending file/plugin, and
fix or revert. Read `AGENTS.md` and the relevant `lua/` file first.

## Order of investigation

1. **Read the error.** Ask for / capture the exact message and the file:line.
   In a session, `:messages` shows recent errors; `:Lazy` shows plugin state.
2. **Reproduce headlessly.** This loads the config without a UI and surfaces
   startup errors:
   ```bash
   nvim --headless "+lua vim.cmd('qa')" 2>&1
   ```
   Non-zero exit or a stack trace points at the culprit file.
3. **Health checks.**
   - `:checkhealth` — overall.
   - `:checkhealth vim.lsp` — LSP-specific.
   - `:LazyHealth` — plugin health + timing.
4. **Inspect LSP logs** when it's an LSP issue: `:LspLog`
   (`~/.local/state/nvim/lsp.log`). For LSP-specific problems, prefer the
   `nvim-lsp` skill.
5. **Check plugin state** in `:Lazy`: is the plugin installed, loaded, updated?
   A red X / missing dependency is a common cause. `:Lazy sync` to repair.
6. **Bisect recent changes.** `git log --oneline -10` and `git diff` in this
   repo. Temporarily comment out the suspect plugin spec or `git stash` to
   confirm; then fix or revert.

## Useful commands

```bash
# Headless load (must exit 0)
nvim --headless "+lua vim.cmd('qa')" 2>&1

# Lua syntax check of a single file
luajit -bl lua/plugins/<file>.lua >/dev/null && echo OK
# (or)
nvim --headless -c "luafile lua/plugins/<file>.lua" -c qa

# Git history of the config
git -C ~/.config/nvim log --oneline -10
git -C ~/.config/nvim diff
```

Fast event context reproduction:

```lua
-- If the call only fails here, it is the fast-context (`E5560`) bug.
vim.uv.new_timer():start(0, 0, function()
  require("<plugin>").some_fn()
end)
```

In-session:

- `:messages` — recent errors and `echo`/`notify` output.
- `:Lazy` — plugin status, `Lazy log` for the full log.
- `:checkhealth`, `:LazyHealth`.
- `:LspLog`, `:LspInfo`.
- `:verbose set <option>?` — where an option was last set.
- `:verbose map <keys>` — where a keymap was defined.

## Common failure modes in this repo

- **Treesitter:** highlighting/indent only start for filetypes listed in both
  `lua/plugins/nvim-treesitter.lua` (install list) and
  `lua/config/autocmds.lua` (FileType list). A missing parser = no highlight.
- **Keymap unused/overridden:** the same key defined in `lua/config/keymaps.lua`
  and a plugin `keys` table; later definition wins. `:verbose map`.
- **LSP not attaching:** see `nvim-lsp`. Often a missing binary or a filetype
  that the server doesn't claim.
- **Formatters:** `conform.nvim` runs on `BufWritePre` with
  `lsp_format = "fallback"`; a missing external formatter (stylua/prettier/black)
  silently skips. `:ConformInfo` shows what conform sees.
- **`lazy-lock.json` conflicts:** never hand-edit; `git checkout lazy-lock.json`
  then `:Lazy sync`.
- **`lcd` side effects:** the `BufEnter` autocmd sets a window-local cwd; odd
  relative-path behavior can come from here (`lua/config/autocmds.lua`).
- **Fast event context (`E5560` / "loop or previous error loading module")**: an
  async callback (`vim.system`, `vim.uv` timer/socket) touched the editor or
  lazily required a UI module (e.g. `snacks.win`, which calls
  `nvim_create_augroup`). Fix: wrap the callback in `vim.schedule` /
  `vim.schedule_wrap`. Reproduce by calling the function inside
  `vim.uv.new_timer():start(0, 0, function() ... end)`; if it only fails there,
  it is this bug.

## Output

Report the root cause, the file:line, and the fix. Confirm the fix with
`nvim --headless "+lua vim.cmd('qa')"` exiting 0. If the cause is outside this
repo (missing system binary, update needed), say so explicitly.
