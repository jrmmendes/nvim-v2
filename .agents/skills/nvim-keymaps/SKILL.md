---
name: nvim-keymaps
description: Conventions for adding or changing keymaps in this Neovim config — global keymaps, plugin keymaps, buffer-local/LspAttach maps, leader keys. Use when the user wants a new keybinding, to change or remove one, or asks where a keymap should live.
compatibility: opencode
---

# Keymaps

Three places a keymap can live. Pick the narrowest one that fits.

1. **Global keymaps** → `lua/config/keymaps.lua` (always loaded).
2. **Plugin keymaps** → the plugin's `keys` table in `lua/plugins/<concern>.lua`
   (enables lazy-loading on keypress).
3. **Buffer-local keymaps** → an autocmd, normally `LspAttach` in
   `lua/plugins/lsp.lua` (only valid for that buffer).

## Leader keys

Defined in `lua/config/options.lua`, **before** lazys load:

```lua
vim.g.mapleader = " "       -- <Space>
vim.g.maplocalleader = "\\" -- <Backslash>
```

Never redefine them elsewhere. They must load before `config.lazy`.

## Global keymaps (`lua/config/keymaps.lua`)

Convention: `local map = vim.keymap.set`, then one line per map with `desc`.

```lua
local map = vim.keymap.set

map("n", "<C-N>", ":bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<leader>rn", function() vim.lsp.buf.rename() end, { desc = "Rename symbol" })
```

- Always include `desc` (shows in `which-key`/`<leader>` listings).
- Add `silent = true` for `:cmd<CR>` maps.
- Modes: pass a string or a table, e.g. `{ "n", "v" }`.

## Plugin keymaps (`keys` in the plugin spec)

Preferred for plugin actions: the plugin stays unloaded until the key is pressed.
Add `desc` to each entry.

```lua
return {
  "folke/snacks.nvim",
  keys = {
    { "<A-g>", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
  },
}
```

See `lua/plugins/snacks.lua` for a full example.

## Buffer-local keymaps (`LspAttach`)

LSP maps are set per buffer in `lua/plugins/lsp.lua` inside an `LspAttach`
autocmd, using the `UserLspConfig` augroup. Add new LSP maps there:

```lua
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Goto Definition" })
```

Do **not** put buffer-local maps in `lua/config/keymaps.lua`.

## Rules

- One change = one obvious home. Do not duplicate the same mapping in two files.
- Changing an existing binding: find where it is defined first (grep the repo),
  then edit that location only.
- Validate with `nvim --headless "+lua vim.cmd('qa')"` (exit 0).
- Remind the user to restart Neovim so global changes take effect.
