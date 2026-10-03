---
name: nvim-lsp
description: How LSP is wired in this Neovim config — nvim-lspconfig configs via vim.lsp.config/vim.lsp.enable, mason + mason-lspconfig, blink.cmp capabilities, per-server overrides, diagnostics. Use when configuring a language server, installing servers with Mason, enabling/disabling a server by filetype, or diagnosing a server that is not attaching.
compatibility: opencode
---

# LSP / language servers

All LSP wiring lives in `core/plugins/lsp.lua`. This config uses **native
Neovim 0.12 APIs** (`vim.lsp.config` / `vim.lsp.enable`), with
`nvim-lspconfig` only as a provider of server definitions, plus `mason.nvim`
and `mason-lspconfig.nvim` for installation.

Read `core/plugins/lsp.lua` before editing — it is the single source of truth.

## How it is set up today

```lua
-- Shared capabilities for every server (from blink.cmp).
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- nvim-lspconfig is the server-config provider:
{ "neovim/nvim-lspconfig", lazy = false, config = function() ... end }

{ "mason-org/mason.nvim", opts = {} }

{
  "mason-org/mason-lspconfig.nvim",
  dependencies = { "mason.nvim", "nvim-lspconfig" },
  opts = { ensure_installed = {}, automatic_enable = true },
}
```

- Diagnostics and the buffer-local LSP keymaps (`gd`, `K`, `gr`, `<leader>ca`,
  ...) are configured here, keymaps inside the `LspAttach` autocmd
  (augroup `UserLspConfig`) with `{ buffer = ev.buf }`.
- `automatic_enable = true` means mason-lspconfig calls `vim.lsp.enable()` for
  each installed server — you do **not** need to enable it manually.

## Install a server (Mason)

1. Add the server name to `ensure_installed` in `core/plugins/lsp.lua`:

   ```lua
   opts = {
     ensure_installed = { "lua_ls", "pyright" },
     automatic_enable = true,
   },
   ```

2. Restart Neovim and run `:Mason` (or `:Lazy sync` then `:Mason`) to install.
   `<Leader>m` opens Mason (mapped in `core/config/keymaps.lua`).
3. Verify with `:LazyHealth` / `:checkhealth vim.lsp`, or `:LspInfo`.

If a server binary is already on `$PATH`, Mason is not strictly required; the
server can still be enabled via `automatic_enable`/`vim.lsp.enable`.

## Per-server overrides

Use `vim.lsp.config("<server>", { ... })` (before enable) to change a single
server's settings, e.g. `lua_ls`:

```lua
vim.lsp.config("lua_ls", {
  settings = {
    Lua = { diagnostics = { globals = { "vim" } } },
  },
})
```

Global defaults for **all** servers go through `vim.lsp.config("*", { ... })`.

## Enable / disable by filetype

- To enable a server explicitly: `vim.lsp.enable("rust_analyzer")`.
- To stop a server from auto-starting, remove it from `ensure_installed` /
  never `enable` it, or disable it in mason-lspconfig opts.
- Attachment is driven by each server's own `filetypes`; check the server def in
  nvim-lspconfig (`:lua print(vim.inspect(vim.lsp.config.rust_analyzer.filetypes))`).

## Diagnose "server not attaching"

1. `:LspInfo` — is the server listed? Is a root dir detected?
2. `:checkhealth vim.lsp` and `:Mason` — installed? on `$PATH`?
3. Open a file of a supported filetype; check `:messages` / `:LspLog`.
4. Confirm capabilities are set: `require("blink.cmp").get_lsp_capabilities()`.
5. If broken behavior is broader than LSP, switch to the `nvim-debug` skill.

## Validation

- `nvim --headless "+lua vim.cmd('qa')"` must exit 0 after edits.
- For a real check, open a file of the server's filetype and confirm attach via
  `:LspInfo`.
