```
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
Mendes' Dotfiles for Neovim (v3)
```

Modern, modular [lazy.nvim](https://lazy.folke.io/installation) config targeting
Neovim 0.12+ and its native APIs (`vim.lsp.config`, `vim.snippet`, `vim.uv`).

## Structure

- `core/config/` — `options`, `keymaps`, `autocmds`, custom `statusline` and the lazy.nvim bootstrap.
- `core/plugins/` — plugin specs, one file per concern, external and local side
  by side (`core/plugins/<name>.lua`), loaded by `core/config/custom.lua`.
- `core/custom/` — local ("custom") plugin trees: pure trees in
  `core/custom/<name>/` (`lua/<name>/init.lua`); the collector injects `dir`/`name`
  into the matching spec.

## Highlights

- **Completion**: [blink.cmp](https://github.com/Saghen/blink.cmp) with native `vim.snippet`.
- **Statusline**: custom powerline-style bar (`core/config/statusline.lua`) — mode-colored
  segments, file icons (mini.icons), diagnostics, git branch/diffs, LSP, search count and clock.
- **UI hub**: [snacks.nvim](https://github.com/folke/snacks.nvim) (picker,
  explorer, dashboard, notifier, zen, terminal, git, and more).
- **LSP**: [mason.nvim](https://github.com/mason-org/mason.nvim) +
  [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) +
  [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), configured through
  `vim.lsp.config` / `vim.lsp.enable`.
- **Treesitter**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  on the `main` branch.
- **Colorscheme**: [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim).

## AI agents

This repo is set up for [OpenCode](https://opencode.ai) agents:

- [`AGENTS.md`](AGENTS.md) — always-active rules, architecture, conventions and a
  task → skill routing map.
- `.opencode/agents/build-nvim.md` — the `Build:Nvim` primary agent: classifies a
  request, picks a skill and delegates execution to a subagent.
- `.agents/skills/nvim-*/SKILL.md` — on-demand procedures for adding plugins,
  keymaps, LSP, options/autocmds, debugging, local custom plugins and read-only
  config questions.
- `.opencode/tools/new-custom-plugin.ts` — native OpenCode custom tool
  (`new-custom-plugin`) that scaffolds a local plugin (`core/plugins/<name>.lua`
  + `core/custom/<name>/`); its `@opencode-ai/plugin` dependency is declared in
  `.opencode/package.json`.

## Install

```bash
git clone git@github.com:jrmmendes/nvim-v2.git ~/.config/nvim
```

## Markdown preview setup

Markdown preview is a dependency-free local plugin (`core/custom/md-preview/`).
It renders Markdown with Neovim's built-in treesitter parser and serves it from
a **detached background daemon** (`nvim --headless`, bound to `127.0.0.1`), so
the preview keeps running after you close Neovim and is reused across sessions.

Open a Markdown file and run `:MD` to start/ensure the daemon, register the
current file and open it in your browser. Every markdown file is served at a
**slug URL** derived from its sanitized path relative to its git root (or your
home), e.g. `/notes/foo`; multiple files can be served by the same daemon at
once. `:MD stop` shuts the daemon down (it also removes the state file). No
keymap is bound.

The daemon exits on its own after **15 minutes of inactivity**, measured from
the last `:MD` call or any HTTP request. No binary to download and no `build`
step. Defaults are configurable in the lazy spec:

```lua
opts = { port = 8765, idle_minutes = 15 }
```

## Requirements

- Neovim >= 0.12
- [git](https://git-scm.com/)
- [node](https://nodejs.org/) (LSP servers / debug adapters)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [cargo](https://www.rust-lang.org/tools/install) (blink.cmp fuzzy matcher, treesitter parsers)
- `tree-sitter-cli` >= 0.26.1 and a C compiler (nvim-treesitter on the `main` branch builds parsers)
- A [Nerd Font](https://www.nerdfonts.com/font-downloads)

Install the Tree-sitter CLI with cargo (needed when your distribution ships an older version, e.g. `tree-sitter-cli` 0.25.10 on Fedora 43):

```bash
cargo install --locked tree-sitter-cli
```

Make sure `~/.cargo/bin` is on your `PATH` — this matters when Neovim is launched from a desktop launcher — and verify the install with `tree-sitter --version`.
