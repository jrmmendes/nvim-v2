return {
    'Fildo7525/pretty_hover',
    event = "LspAttach",
	  opts = {},
    config = function()
		    require("pretty_hover").setup({})
        vim.keymap.set('n', '<C-h>', function()
            require('pretty_hover').hover()
        end, { desc = 'Trigger pretty_hover' })
    end
}
