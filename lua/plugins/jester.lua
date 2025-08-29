return {
    'David-Kunz/jester',
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        local jester = require('jester')

        vim.api.nvim_create_user_command('JestRun', function()
            jester.run()
        end, {})

        vim.api.nvim_create_user_command('JestRunFile', function()
            jester.run_file()
        end, {})

        vim.api.nvim_create_user_command('JestRunLast', function()
            jester.run_last()
        end, {})

        vim.api.nvim_create_user_command('JestDebug', function()
            jester.debug()
        end, {})

        vim.api.nvim_create_user_command('JestDebugFile', function()
            jester.debug_file()
        end, {})

        vim.api.nvim_create_user_command('JestDebugLast', function()
            jester.debug_last()
        end, {})
    end
}
