return {
    "hiphish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        vim.g.rainbow_delimiters = {
            -- The default query colors (), [] and {}. rainbow-parens does the same minus JSX
            -- tags, but only javascript and tsx have it: set for every language, it left all
            -- the others (lua, python, ...) with no rainbow at all.
            query = {
                [""] = "rainbow-delimiters",
                javascript = "rainbow-parens",
                tsx = "rainbow-parens",
            },
        }
    end,
}
