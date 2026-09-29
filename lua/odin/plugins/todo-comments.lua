return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList" },
    keys = {
        { "<leader>pt", "<cmd>TodoTelescope<cr>", desc = "Telescope: TODO comments" },
        { "]t",         function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
        { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous TODO comment" },
    },
    opts = {},
}
