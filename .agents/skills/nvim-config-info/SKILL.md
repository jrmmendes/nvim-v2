---
name: nvim-config-info
description: Answers read-only questions about the current state of this Neovim config — which plugins/keymaps/options/autocmds exist, LSP setup, structure. Use when the user asks what a keymap does, where something is configured, what plugins are installed, or how a part of the config works. Never modifies files.
compatibility: opencode
---

# Answering questions about the Neovim config (read-only)

**This skill never edits files.** It only reads and explains. If the user asks
for a change, route to the appropriate skill (`nvim-add-plugin`, `nvim-keymaps`,
`nvim-lsp`, `nvim-options-autocmds`, `nvim-debug`).

## Where to look

| Question                                  | Read                                            |
| ----------------------------------------- | ----------------------------------------------- |
| Overall structure / entry point           | `AGENTS.md`, `README.md`, `init.lua`            |
| Editor options, leader keys               | `core/config/options.lua`                        |
| Global keymaps                            | `core/config/keymaps.lua`                        |
| Autocmds                                  | `core/config/autocmds.lua`                       |
| Statusline                                | `core/config/statusline.lua`                     |
| lazy.nvim bootstrap / loading             | `core/config/lazy.lua`                           |
| Plugins (one per concern)                 | `core/plugins/*.lua`                             |
| LSP / mason                               | `core/plugins/lsp.lua`                           |
| Completion / capabilities                 | `core/plugins/completion.lua`                    |
| Formatting                                | `core/plugins/conform.lua`                       |
| Treesitter                                | `core/plugins/nvim-treesitter.lua`               |
| UI (picker, explorer, dashboard, terminal)| `core/plugins/snacks.lua`                        |
| Colorscheme                               | `core/plugins/colorscheme.lua`                   |
| Plugin keymaps (lazy)                     | each `core/plugins/*.lua` `keys` table           |
| Installed plugin versions                 | `lazy-lock.json` (read only — never edit)       |

## How to answer well

- **Read the actual files** before asserting; do not guess from memory.
- For keymaps: combine `core/config/keymaps.lua` (global) with the `keys` tables
  found across `core/plugins/*.lua` (plugin/lazy). LSP buffer-local maps live in
  the `LspAttach` autocmd in `core/plugins/lsp.lua`. Always report the leader
  context (`<leader>` = Space, `<localleader>` = `\`).
- For plugins: list the repo, lazy-load trigger (`event`/`ft`/`cmd`), and what it
  does. Note `lazy = false` ones (colorscheme, snacks, treesitter, lspconfig).
- For options: quote the value from `options.lua`.
- For "is X configured?": grep the repo and answer yes/no with the file:line.
- Prefer concise summaries and `file_path:line` references.

## Useful read-only commands

```bash
# List plugins files
ls core/plugins
# Find a keymap / option / plugin across the config
rg -n "pattern" core
```

Do not run commands that modify state; `rg`/`ls`/`cat` are fine.
