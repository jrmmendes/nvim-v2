return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        bigfile = { enabled = true },
        dashboard = { enabled = true },
        explorer = { enabled = true },
        indent = { enabled = true },
        input = {
            icon = " ",
            icon_hl = "SnacksInputIcon",
            icon_pos = "left",
            prompt_pos = "title",
            win = { style = "input" },
            expand = true,
        },
        picker = {
            enabled = true,
            sources = {
                explorer = {
                    jump = { close = true },
                    layout = { layout = { position = "right" } }
                }
            }
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
    },
    keys = {
        { "<A-p>",  function() Snacks.picker() end,                 desc = "Smart Find Files" },
        { "<A-,>",  function() Snacks.picker.buffers() end,         desc = "Buffers" },
        { "<A-g>",  function() Snacks.picker.grep() end,            desc = "Grep" },
        { "<A-c>:", function() Snacks.picker.command_history() end, desc = "Command History" },
        { "<A-n>",  function() Snacks.picker.notifications() end,   desc = "Notification History" },
        { "<A-s>",  function() Snacks.explorer() end,               desc = "File Explorer" },
    }
}
