# Plano persistido

- Data/hora: 2026-09-30 22:59 (GMT-3)
- Modo: Plan:zed
- Projeto: /home/mendes/.config/nvim
- Aprovação: `y` (via tool question)

---

# Modernização e consolidação da config Neovim

Reescrever a config (Neovim 0.12.0) em estrutura padrão e modular, adotando o que há de mais recente (APIs nativas 0.11+, blink.cmp, gitsigns, snacks como hub) e eliminando duplicações, dead code e múltiplas fontes de verdade. O treesitter passa a ser corrigido via migração para a branch `main` e mantido ativo — o que **substitui** o pedido original de desativá-lo (decisão registrada na análise de ambiguidade).

## Análise de Ambiguidade

- [ ] Ambiguidades detectadas e resolvidas conforme abaixo:
  - **Versão do Neovim**: 0.12.0 confirmado pelo usuário → alvo de APIs 0.10+/0.11+ nativas (`vim.lsp.config`, `vim.lsp.enable`, `vim.uv`, `vim.snippet`). A verificação `nvim --version`/`:checkhealth` fica como etapa de validação.
  - **Escopo**: reescrita moderna completa.
  - **Completion**: `blink.cmp` (remove nvim-cmp, cmp-*, lspkind; snippets via engine nativa `vim.snippet`).
  - **Statusline**: `snacks.statusline` (remove vim-airline + themes + vim-devicons).
  - **Explorador**: `snacks.explorer` (remove nvim-tree e nerdtree).
  - **Treesitter**: manter e corrigir migrando para a branch `main`, reativando highlight/indent. Contradiz o pedido inicial de "desativar"; o usuário confirmou que esta decisão prevalece.
  - **Git signs**: `gitsigns.nvim` (remove vim-gitgutter; mantém fugitive e diffview).
  - **Colorscheme**: `gruvbox.nvim` como fonte única (remove darcula, morhetz/gruvbox e o tema do airline).

## Plano de Execução

1 - **Diagnóstico e baseline**: executar `nvim --version` e `nvim "+checkhealth" +qa` para confirmar 0.12.0 e dependências (git, node, ripgrep, cargo se for compilar blink). Registrar o estado atual e fazer backup do `lazy-lock.json` antes de mexer.

2 - **Nova espinha dorsal de config**: reduzir `init.lua` para orquestrar `require("config.options")`, `require("config.keymaps")`, `require("config.autocmds")` e `require("config.lazy")`; em `lua/config/lazy.lua` manter apenas o bootstrap do lazy.nvim, `mapleader`/`maplocalleader` e `require("lazy").setup({ import = "plugins" })`, eliminando a lista explícita e repetida de imports.

3 - **Options como fonte única**: criar `lua/config/options.lua` movendo todos os `vim.opt` hoje em `lazy.lua` (number, relativenumber, showtabline, indentação, textwidth, scrolloff, guifont, hidden, showcmd, termguicolors, updatetime, signcolumn, clipboard, undofile/undodir, splitright/splitbelow), documentando cada um de forma concisa.

4 - **Keymaps como fonte única**: criar `lua/config/keymaps.lua` consolidando os atalhos hoje espalhados em `lazy.lua` (buffer nav `<C-N>/<C-P>/<C-D>`, `<A-f>` para snacks.picker, `<Leader>m` Mason, `<Leader>l` Lazy, `<A-d>` diffview, `<leader>rn`) e removendo comandos órfãos que apontam para plugins inexistentes (ex.: comando `Todo` apontando para `Dooing`).

5 - **Autocmds deduplicados**: criar `lua/config/autocmds.lua` com uma única autocmd de indentação (hoje há duas duplicadas definindo expandtab/tabstop/shiftwidth), o `lcd %:p:h` com salvaguardas, `FileType` para iniciar treesitter e um gancho opcional de format-on-save via conform.

6 - **Colorscheme único**: criar `lua/plugins/colorscheme.lua` com `ellisonleao/gruvbox.nvim` (`priority = 1000`, `lazy = false`, setando `colorscheme gruvbox` e `background = dark`); deletar `lua/plugins/colorschemes.lua` e `lua/plugins/gruvbox.lua`, removendo darcula e morhetz/gruvbox.

7 - **snacks como hub de UI**: expandir `lua/plugins/snacks.lua` (statusline, git/gitbrowse, zen, terminal, bufdelete, rename, words, picker com explorer já existente) e ajustar `showtabline`/`laststatus`; deletar os plugins que ele substitui — `indent.lua` (indent-blankline), `fidget.lua` (notifier), `startify.lua` (dashboard), `nerdtree.lua`/`nvim-tree.lua` (explorer), `bmessages.lua`, `goyo.lua` (zen) e o `vim-maximizer` hoje dentro de `dap.lua`.

8 - **Completion com blink.cmp**: criar `lua/plugins/completion.lua` com `saghen/blink.cmp` (preset de keymap, sources lsp/path/buffer/snippets, `signature`, documentação, `fuzzy` via binário pré-compilado); deletar `lua/plugins/nvim-cmp.lua` e o bloco nvim-cmp duplicado em `mason.lua`, removendo nvim-cmp, cmp-*, lspkind e LuaSnip.

9 - **LSP moderno (APIs 0.11+)**: refatorar `mason.lua` em `lua/plugins/lsp.lua` usando `mason.nvim` + `mason-lspconfig.nvim` v2 com `automatic_enable = true`, configuração central por `vim.lsp.config("*", { capabilities = blink.cmp.get_lsp_capabilities(), ... })` e habilitação por `vim.lsp.enable`, mantendo nvim-lspconfig apenas como provedor de configs; remover o monkeypatch de `open_floating_preview` e mover os keymaps de `LspAttach` para o mesmo arquivo.

10 - **Formatting e linting**: separar `conform.nvim` (formatters por filetype + format-on-save) e configurar `nvim-lint` num arquivo dedicado, removendo o acúmulo atual dentro de `mason.lua` e o keymap duplicado `<leader>f`/`<space>f`.

11 - **Treesitter na branch `main`**: reescrever `lua/plugins/nvim-treesitter.lua` para a API nova (`require("nvim-treesitter").install({...})`, `vim.treesitter.start()` via `FileType`, `indentexpr`), manter `highlight`/`indent` ativos, atualizar dependentes (`jester`, `codecompanion`) para a branch `main` e remover `vim-polyglot` (não mantido, coberto por treesitter + filetype nativo).

12 - **Git e demais UI**: criar `lua/plugins/gitsigns.lua` (sinais, hunk actions, blame) e deletar `lua/plugins/vim-gitgutter.lua`; consolidar `mini.lua` como fonte de text-objects/ícones (`mini.pairs`, `mini.icons` com mock de devicons, `mini.surround` substituindo vim-surround, `mini.map`; remover `mini.comment`, coberto pelo `gc` nativo) e deletar `lua/plugins/surround.lua`.

13 - **Substituições de UX**: trocar `vim-auto-save` por `okuuva/auto-save.nvim`, `vim-css-color` por `brenoprata10/nvim-highlight-colors`, e `pretty_hover` por hover nativo configurado; deletar `lua/plugins/autoclose.lua` (mini.pairs cobre), `lua/plugins/easymotion.lua`, `lua/plugins/llm-ls.lua`, `lua/plugins/codi.lua`, `lua/plugins/diagnostic-window.lua`, `lua/plugins/coc.lua`, `coc-settings.json` e `lua/plugins/claude-code.lua` (codecompanion fica como único plugin de IA).

14 - **Plugins de feature reorganizados**: renomear `dadbob.lua`→`dadbod.lua`, enxugar `dap.lua` (remover import duplicado e persistent-breakpoints desabilitado), atualizar deps do `codecompanion` (picker `snacks`), limpar `web-tools.lua` e `jester.lua`, e manter `dooing`/`lazyclip` devidamente importados e com keymaps válidos.

15 - **Limpeza e verificação final**: remover `lua/config/tags` (artefato ctags gerado) e adicionar `.gitignore`; rodar `:Lazy sync` + `:checkhealth`, abrir arquivos `.lua`/`.ts` e validar LSP, blink, treesitter, gitsigns, snacks.picker/explorer/dashboard e conform; atualizar `README.md` (requisitos e remoção do Ag).
