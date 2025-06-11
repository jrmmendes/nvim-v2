return {
  -- Required for <C-f> widget behaviour (dressing.nvim)
  -- This can be lazy-loaded as it's not critical for core LSP setup.
  {
    'stevearc/dressing.nvim',
    opts = {},
    event = 'VeryLazy'
  },

  -- Mason.nvim itself: Manages installation of LSP servers, formatters, linters, etc.
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    },
  },

  -- nvim-lspconfig: The core LSP client for Neovim.
  -- This provides the `vim.lsp` API and the `lspconfig` table.
  {
    "neovim/nvim-lspconfig",
    -- Load this when a buffer is read, which is early enough for LSP functionality.
    event = "BufReadPost",
  },

  -- mason-lspconfig.nvim: The bridge between Mason and nvim-lspconfig.
  -- This plugin automates the setup of language servers installed by Mason using nvim-lspconfig.
  {
    "mason-org/mason-lspconfig.nvim",
    -- Crucial: Explicitly pull from the 'main' branch to ensure the latest version with 'setup_handlers'.
    branch = "main",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
      -- Optional: For integrating LSP capabilities with nvim-cmp. Remove if not using nvim-cmp.
      "hrsh7th/cmp-nvim-lsp",
    },
    -- The 'config' function runs after the plugin and its dependencies are loaded.
    config = function()
      local lspconfig = require('lspconfig')
      local mason_lspconfig = require('mason-lspconfig')

      -- Retrieve LSP capabilities. If nvim-cmp is installed, use its default capabilities.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      if cmp_nvim_lsp_ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- Configure mason-lspconfig to set up language servers using nvim-lspconfig's `setup` method.
      -- This function is called for each language server Mason manages.
      mason_lspconfig.setup {
        function(server_name)
          lspconfig[server_name].setup {
            capabilities = capabilities,
            on_attach = function(client, bufnr)
              -- This `on_attach` function is executed when an LSP server successfully
              -- attaches to a buffer. It's the ideal place to define buffer-local keymaps for LSP actions.

              -- Ensure completion provider is fully enabled if the server supports it
              if client.server_capabilities.completionProvider then
                client.server_capabilities.completionProvider.resolveProvider = true
                client.server_capabilities.completionProvider.triggerCharacters = { '.', ':', '/', '\\', '-', '_' }
              end

              -- LSP Keybindings (buffer-local, apply only when LSP is active for the buffer)
              local opts = { noremap = true, silent = true }

              -- Go to definition: THE 'gd' ACTION
              vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

              -- Diagnostic navigation keymaps
              vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
              vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
            end,
          }
        end,
      }

      -- Tell mason-lspconfig which language servers to ensure are installed by Mason.
      mason_lspconfig.setup {
        ensure_installed = { "ts_ls", "biome", "lua_ls" },
        -- Add any other language servers you want Mason to manage here.
      }

      -- Configure Neovim's built-in diagnostics appearance
      vim.diagnostic.config {
        virtual_text = true,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      }
    end, -- End of 'config' function for mason-lspconfig.nvim
  },
}
