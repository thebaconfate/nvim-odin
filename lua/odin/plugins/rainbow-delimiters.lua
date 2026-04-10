return {
    "hiphish/rainbow-delimiters.nvim",
    config = function()
        vim.g.rainbow_delimiters = {
            query = {
                [''] = 'rainbow-parens', -- ONLY parentheses/brackets
            },
        }
    end
}
