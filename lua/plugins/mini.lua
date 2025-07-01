return {
    enabled = true,
    'echasnovski/mini.nvim',
    version = false,
    config = function()
        require('mini.pairs').setup()
        require('mini.map').setup()
        require('mini.comment').setup()
        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'lua', 'markdown', 'json', 'yaml' },
            callback = function()
                if package.loaded['mini.map'] then
                    require('mini.map').open()
                end
            end,
        })
    end
}
