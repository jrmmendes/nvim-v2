---
name: nvim-options-autocmds
description: Conventions for changing editor options and autocmds in this Neovim config — lua/config/options.lua and lua/config/autocmds.lua patterns, augroups, indent/filetype autocmds. Use when the user wants to change an editor option, add or fix an autocmd, or adjust indentation/filetype behavior.
compatibility: opencode
---

# Options and autocmds

Two files, two responsibilities:

- `lua/config/options.lua` — all `vim.opt` / `vim.o` / `vim.g` settings.
- `lua/config/autocmds.lua` — all global autocmds (deduplicated).

Both are required by `init.lua` in order. Never scatter options/autocmds into
plugin files or `init.lua`.

## Options (`lua/config/options.lua`)

The file aliases `local opt = vim.opt` and groups options by concern with
comments. Match that structure.

```lua
local opt = vim.opt

-- Tabs / indentation.
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
```

Rules:

- Add a new option under the closest existing comment group (or add a new group).
- Leader keys are set here and **must stay here**:
  ```lua
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"
  ```
  They have to load before `config/lazy`.
- Use `vim.opt` for list-like options and `vim.o`/`vim.opt` for scalars; follow
  the existing style in the file.
- Prefer native options over plugins when Neovim 0.12 already supports it.

## Autocmds (`lua/config/autocmds.lua`)

Current autocmds and their patterns:

- `{ "BufEnter", "FileType" }` — enforce `expandtab/tabstop/shiftwidth`.
- `BufEnter` — `lcd` to the file's directory, guarded for special/unnamed
  buffers (`buftype == ""` and a real path).
- `FileType` (a fixed list of filetypes) — start treesitter and set
  `indentexpr`.

When adding an autocmd:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "python" },
  group = vim.api.nvim_create_augroup("UserSomething", { clear = true }),
  callback = function(ev)
    -- use ev.buf / ev.file / ev.match
  end,
})
```

Rules:

- **Always** use `vim.api.nvim_create_augroup(<name>, { clear = true })` for a
  named group so re-sourcing is idempotent. Pick a `User*` group name.
- Prefer `callback = function(ev) ... end` over `command`/`vim.cmd` strings.
- Use `pattern` rather than checking `vim.bo.filetype` in the callback.
- The `lcd` autocmd changes the *window-local* cwd — be careful; keep the
  `buftype`/path guards or you will break special buffers (terminals, pickers).
- The indentation autocmd intentionally overrides per-filetype indentation
  (2-space everywhere). Do not "fix" it without confirming with the user.
- Treesitter filetypes are duplicated in `lua/plugins/nvim-treesitter.lua`
  (`require("nvim-treesitter").install({...})`). If you add a filetype to one
  list, update the other, or highlighting/indent silently won't start.

## Validation

- `nvim --headless "+lua vim.cmd('qa')"` must exit 0 after edits.
- For autocmd behavior, reproduce in a real session and check `:messages`.
- If the change breaks startup or behavior, use the `nvim-debug` skill.
