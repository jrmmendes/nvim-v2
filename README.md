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

Markdown preview is a local plugin (`core/custom/md-preview/`) whose rendering
and HTTP daemon is a **self-contained [Bun](https://bun.sh) binary**
(`core/custom/md-preview/server/`). It renders Markdown with
[markdown-it](https://github.com/markdown-it/markdown-it) and highlights code
with [Shiki](https://shiki.style/), and renders
[Mermaid](https://mermaid.js.org/) `12.2.0` diagrams **client-side** from a
bundle embedded in the binary — no CDN, no network at runtime, no treesitter.

YAML frontmatter (a `---` block at the very top) is parsed and hidden from the
body: `title` becomes the page `<title>`, and `author`/`date`/`description`/
`tags` render as a compact metadata block above the content. Malformed or
unterminated frontmatter is left untouched as regular content.

Open a Markdown file and run `:MD` to build/start the daemon, register the
current file and open it in your browser. Every markdown file is served at a
**slug URL** derived from its sanitized path relative to its git root (or your
home), e.g. `/notes/foo`; multiple files can be served by the same daemon at
once. `:MD stop` shuts the daemon down (it also removes the state file). No
keymap is bound.

The daemon survives closing Neovim (it is spawned detached and binds to
`127.0.0.1` only) and exits on its own after **15 minutes of inactivity**,
measured from the last `:MD` call or any HTTP request. Defaults are configurable
in the lazy spec:

```lua
opts = {
  port = 8765,
  idle_minutes = 15,
  theme = "auto",      -- auto | github-dark | github-light | dracula | nord |
                       -- solarized-dark | solarized-light | gruvbox-dark | gruvbox-light
  auto_build = true,   -- build the server binary on first :MD if missing
}
```

Themes: `theme = "auto"` follows the OS (`prefers-color-scheme`) with a
light/dark Shiki pair; a named theme renders that theme directly. The page has a
fixed theme `<select>` that remembers your choice in a cookie across
live-reloads, and `?theme=<name>` in the URL overrides both. Live-reload polls
the per-slug `/version` endpoint, so unsaved edits (pushed on `TextChanged`) and
external file changes show up automatically.

### Building the server binary

The daemon is a Bun-compiled binary and is **not committed**. [Install
Bun](https://bun.sh) and either let `:MD` auto-build it on first use, or build it
manually:

```bash
bash ~/.config/nvim/core/custom/md-preview/server/build.sh
```

This runs `bun install --frozen-lockfile --production` and emits
`core/custom/md-preview/server/bin/md-preview-server`. lazy.nvim also runs this
script through the plugin's `build` hook on install/update.

Supply chain: direct dependencies are **pinned to exact versions** in
`server/package.json` (no `^`/`~`), `server/bun.lock` pins every transitive
dependency with integrity hashes, and the build installs with
`--frozen-lockfile`, so any drift between `package.json` and the lock aborts the
build instead of silently resolving new versions. `server/bunfig.toml` sets
`install.exact = true` and `install.auto = "disable"`, and `trustedDependencies`
is empty, so no dependency runs lifecycle scripts and nothing is auto-installed
at runtime. `node_modules/` and `bin/` are gitignored; `bun.lock` and
`bunfig.toml` are committed.

## Requirements

- Neovim >= 0.12
- [git](https://git-scm.com/)
- [bun](https://bun.sh) (Markdown preview server binary)
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
