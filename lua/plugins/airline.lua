return {
    -- Airline/Statusline plugin
    'vim-airline/vim-airline',
    lazy=false,
    priority=1000,
    dependencies = {
        'vim-airline/vim-airline-themes',
        'tpope/vim-fugitive',
        'ryanoasis/vim-devicons'
    },
    config = function()
        vim.g.airline_symbols = vim.g.airline_symbols or {}
        -- Airline configuration
        vim.g.airline_powerline_fonts = 1
        vim.g.Powerline_symbols = 'unicode'
        vim.g.gruvbox_contrast_dark = "hard"
        --vim.g.airline_theme="base16_gruvbox_dark_soft"
        vim.g.airline_theme="minimalist"

        -- Tabline extensions
        vim.g['airline#extensions#tabline#enabled'] = 1
        vim.g['airline#extensions#tabline#show_tab_nr'] = 1
        vim.g['airline#extensions#tabline#tab_nr_type'] = 2
        vim.g['airline#extensions#branch#enabled'] = 0
        vim.g['airline#extensions#tabline#show_tab_type'] = 1
        vim.g['airline#extensions#tabline#buffers_label'] = 'BUFFERS'
        vim.g['airline#extensions#tabline#tabs_label'] = 'TABS'
        -- Unicode symbols for separators
        vim.g.airline_left_sep = ''
        vim.g.airline_left_alt_sep = ''
        vim.g.airline_right_sep = ''
        vim.g.airline_right_alt_sep = ''
        vim.g.airline_symbols.branch = '>'


        -- +-----------------------------------------------------------------------------+
        -- | A | B |                     C                            X | Y | Z |  [...] |
        -- +-----------------------------------------------------------------------------+
        vim.g.airline_section_b = '%{FugitiveHead() == "" ? "" : " " . FugitiveHead()}'
    end
}
