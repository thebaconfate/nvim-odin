return {
    -- https://github.com/Mofiqul/vscode.nvim
    'Mofiqul/vscode.nvim',
    config = function()
        require('vscode').setup({
            -- Disable nvim-tree background color
            disable_nvimtree_bg = true, -- optional
            -- Enable transparent background
            -- transparent = true,
            -- Underline `@markup.link.*` variants
            underline_links = true,
            -- Disable italics
            italic_comments = false,
            italic_keywords = false,
            italic_functions = false,
            italic_variables = false,
        })
    end
}
