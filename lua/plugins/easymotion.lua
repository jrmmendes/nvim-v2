return {
    'easymotion/vim-easymotion',
    config = function()
        -- Set up key mappings for EasyMotion
        vim.g.EasyMotion_do_mapping = 0 -- Disable default mappings

        -- Example key mappings
        vim.keymap.set('n', '<Leader>w', '<Plug>(easymotion-w)', { silent = true })
        vim.keymap.set('n', '<Leader>e', '<Plug>(easymotion-e)', { silent = true })
        vim.keymap.set('n', '<Leader>b', '<Plug>(easymotion-b)', { silent = true })
        vim.keymap.set('n', '<Leader>j', '<Plug>(easymotion-j)', { silent = true })
        vim.keymap.set('n', '<Leader>k', '<Plug>(easymotion-k)', { silent = true })

        -- Customize EasyMotion behavior (optional)
        vim.g.EasyMotion_smartcase = 1 -- Enable smart case matching
        vim.g.EasyMotion_use_smartsign_us = 1 -- Use smart sign for jump labels
    end,
}
