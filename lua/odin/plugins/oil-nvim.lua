return {
    'stevearc/oil.nvim',
    -- One icon provider for the whole config: lualine, telescope and render-markdown
    -- all use nvim-web-devicons, so oil does too rather than pulling in mini.icons.
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- NOTE: deliberately NOT lazy-loaded. default_file_explorer only takes over from
    -- netrw if oil is loaded before a directory buffer is opened (`nvim .`).
    lazy = false,
    config = function()
        require("oil").setup({
            default_file_explorer = true,
            columns = { "icon" },
            view_options = {
                show_hidden = true
            },
            keymaps = {
                ["<C-p>"] = false,
            },
            preview = {
                layout = "vertical",       -- Vertical split
                vertical = { width = 40 }, -- Customize the width
            },
        })

        vim.keymap.set("n", "<leader>pv", ":Oil<CR>", { desc = "Open Oil" })
    end
}
