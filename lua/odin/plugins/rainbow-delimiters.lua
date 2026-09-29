return {
    "hiphish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        vim.g.rainbow_delimiters = {
            query = {
                [''] = 'rainbow-parens', -- ONLY parentheses/brackets
            },
        }
    end
}
