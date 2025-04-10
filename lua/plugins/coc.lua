return {
    {
        enabled=false,
        'neoclide/coc.nvim',
        branch = 'release',
        build = ':CocInstall coc-json coc-tsserver coc-pyright',
        config = function()
            -- Global configuration
            vim.opt.hidden = true
            vim.opt.backup = false
            vim.opt.writebackup = false
            vim.opt.cmdheight = 2
            vim.opt.updatetime = 300
            vim.opt.shortmess:append('c')
            vim.opt.signcolumn = 'yes'

            -- Custom functions
            local function check_back_space()
                local col = vim.fn.col('.') - 1
                return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
            end

            -- Key mappings
            local opts = {silent = true, noremap = true, expr = true}
            local keyset = vim.keymap.set

            -- Tab completion
            keyset('i', '<TAB>', function()
                if vim.fn.pumvisible() == 1 then
                    return '<C-n>'
                elseif check_back_space() then
                    return '<TAB>'
                else
                    return vim.fn['coc#refresh']()
                end
            end, opts)

        keyset('i', '<S-TAB>', function()
            if vim.fn.pumvisible() == 1 then
                return '<C-p>'
            else
                return '<C-h>'
            end
        end, opts)

    -- Use <c-space> to trigger completion
    keyset('i', '<c-space>', vim.fn['coc#refresh'], opts)

    -- Make <CR> auto-select first completion item
    keyset('i', '<cr>', function()
        if vim.fn.pumvisible() == 1 then
            return '<C-y>'
        else
            return '<C-g>u<CR>'
        end
    end, opts)

-- Navigation and GoTo mappings
keyset('n', '[g', '<Plug>(coc-diagnostic-prev)', {silent = true})
keyset('n', ']g', '<Plug>(coc-diagnostic-next)', {silent = true})
keyset('n', 'gd', '<Plug>(coc-definition)', {silent = true})
keyset('n', 'gy', '<Plug>(coc-type-definition)', {silent = true})
keyset('n', 'gi', '<Plug>(coc-implementation)', {silent = true})
keyset('n', 'gr', '<Plug>(coc-references)', {silent = true})

-- Use K to show documentation
keyset('n', 'K', function()
    local filetype = vim.bo.filetype
    if vim.tbl_contains({'vim', 'help'}, filetype) then
        vim.cmd('help ' .. vim.fn.expand('<cword>'))
    else
        vim.fn['CocAction']('doHover')
    end
end, {silent = true})

            -- Highlight symbol under cursor
            vim.api.nvim_create_autocmd('CursorHold', {
                    callback = function()
                        vim.fn['CocActionAsync']('highlight')
                    end
                })

            -- Rename current word
            keyset('n', '<leader>rn', '<Plug>(coc-rename)', {silent = true})

            -- Formatting
            keyset('x', '<leader>f', '<Plug>(coc-format-selected)', {silent = true})
            keyset('n', '<leader>f', '<Plug>(coc-format-selected)', {silent = true})

            -- Code actions
            keyset('x', '<leader>a', '<Plug>(coc-codeaction-selected)', {silent = true})
            keyset('n', '<leader>a', '<Plug>(coc-codeaction-selected)', {silent = true})
            keyset('n', '<leader>ac', '<Plug>(coc-codeaction)', {silent = true})
            keyset('n', '<leader>qf', '<Plug>(coc-fix-current)', {silent = true})

            -- CoC List mappings
            keyset('n', '<space>a', ':<C-u>CocList diagnostics<cr>', {silent = true})
            keyset('n', '<space>e', ':<C-u>CocList extensions<cr>', {silent = true})
            keyset('n', '<space>c', ':<C-u>CocList commands<cr>', {silent = true})
            keyset('n', '<space>o', ':<C-u>CocList outline<cr>', {silent = true})
            keyset('n', '<space>s', ':<C-u>CocList -I symbols<cr>', {silent = true})
            keyset('n', '<space>j', ':<C-u>CocNext<CR>', {silent = true})
            keyset('n', '<space>k', ':<C-u>CocPrev<CR>', {silent = true})
            keyset('n', '<space>p', ':<C-u>CocListResume<CR>', {silent = true})

            -- Add commands
            vim.api.nvim_create_user_command('Format', function()
                vim.fn['CocAction']('format')
            end, {})

        vim.api.nvim_create_user_command('Fold', function(opts)
            vim.fn['CocAction']('fold', opts.args)
        end, {nargs = '?'})

    vim.api.nvim_create_user_command('OR', function()
        vim.fn['CocAction']('runCommand', 'editor.action.organizeImport')
    end, {})
        end
    }
}
