return {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
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
