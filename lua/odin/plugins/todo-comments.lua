return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoQuickFix", "TodoLocList" },
    keys = {
        -- todo-comments adds this picker source to snacks when it loads
        {
            "<leader>pt",
            function()
                Snacks.picker.todo_comments()
            end,
            desc = "Picker: TODO comments",
        },
        {
            "]t",
            function()
                require("todo-comments").jump_next()
            end,
            desc = "Next TODO comment",
        },
        {
            "[t",
            function()
                require("todo-comments").jump_prev()
            end,
            desc = "Previous TODO comment",
        },
    },
    opts = {},
}
