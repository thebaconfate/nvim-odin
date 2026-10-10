return {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- Required dependency
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("gitsigns").setup({
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                map("n", "]c", function()
                    gs.nav_hunk("next")
                end, "Git: next hunk")
                map("n", "[c", function()
                    gs.nav_hunk("prev")
                end, "Git: previous hunk")

                map("n", "<leader>hs", gs.stage_hunk, "Git: stage hunk")
                map("n", "<leader>hr", gs.reset_hunk, "Git: reset hunk")
                map("v", "<leader>hs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Git: stage selection")
                map("v", "<leader>hr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Git: reset selection")
                map("n", "<leader>hp", gs.preview_hunk, "Git: preview hunk")
                map("n", "<leader>hb", function()
                    gs.blame_line({ full = true })
                end, "Git: blame line")
                map("n", "<leader>hd", gs.diffthis, "Git: diff against index")
            end,
        })
    end,
}
