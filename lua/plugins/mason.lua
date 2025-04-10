return {
    {
        'stevearc/dressing.nvim',
        opts = {},
        event='VeryLazy'
    },
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    }
}
