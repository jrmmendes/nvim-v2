return { 
    enabled = true,
    'echasnovski/mini.nvim', version = false,
    config = function()
        require('mini.pairs').setup()
    end
}
