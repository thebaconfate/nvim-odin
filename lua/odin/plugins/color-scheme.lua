return {
    -- https://github.com/Mofiqul/vscode.nvim
    "Mofiqul/vscode.nvim",
    -- Load before everything else: after/plugin/color-scheme.lua used to re-apply
    -- this at startup, which is no longer needed now that it is set here.
    lazy = false,
    priority = 1000,
    config = function()
        require("vscode").setup({
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
        vim.cmd.colorscheme("vscode")
        -- vscode.nvim styles every BlinkCmp* group except this one. Link it to the
        -- theme's struck-through nvim-cmp group so deprecated items stay crossed out.
        vim.api.nvim_set_hl(0, "BlinkCmpLabelDeprecated", { link = "CmpItemAbbrDeprecated" })
    end,
}
