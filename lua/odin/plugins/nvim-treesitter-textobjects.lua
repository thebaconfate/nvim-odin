return {
    -- NOTE: must track `main`. On nvim-treesitter's main branch the textobjects module
    -- was split into this plugin, and its API differs from the old master-branch one:
    -- keymaps are set by hand rather than through a `textobjects = {}` config block.
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter-textobjects").setup({
            select = {
                -- Jump forward to the next textobject if the cursor is not inside one
                lookahead = true,
            },
            move = {
                -- Motions land in the jumplist, so <C-o> gets you back
                set_jumps = true,
            },
        })

        local select = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")
        local swap = require("nvim-treesitter-textobjects.swap")

        -- Select: vaf / vif etc. Operator-pending too, so `daf`, `cif`, `yac` all work.
        local selections = {
            ["af"] = { "@function.outer", "function" },
            ["if"] = { "@function.inner", "function body" },
            ["ac"] = { "@class.outer", "class" },
            ["ic"] = { "@class.inner", "class body" },
            ["aa"] = { "@parameter.outer", "parameter" },
            ["ia"] = { "@parameter.inner", "parameter" },
            ["al"] = { "@loop.outer", "loop" },
            ["il"] = { "@loop.inner", "loop body" },
            ["ai"] = { "@conditional.outer", "conditional" },
            ["ii"] = { "@conditional.inner", "conditional body" },
            ["a/"] = { "@comment.outer", "comment" },
        }
        for lhs, spec in pairs(selections) do
            vim.keymap.set({ "x", "o" }, lhs, function()
                select.select_textobject(spec[1], "textobjects")
            end, { desc = "Select " .. spec[2] })
        end

        -- Move: ]m / [m between functions, ]] / [[ between classes.
        local moves = {
            { "]m", move.goto_next_start,     "@function.outer", "Next function start" },
            { "]M", move.goto_next_end,       "@function.outer", "Next function end" },
            { "[m", move.goto_previous_start, "@function.outer", "Previous function start" },
            { "[M", move.goto_previous_end,   "@function.outer", "Previous function end" },
            { "]]", move.goto_next_start,     "@class.outer",    "Next class start" },
            { "[[", move.goto_previous_start, "@class.outer",    "Previous class start" },
        }
        for _, m in ipairs(moves) do
            local lhs, fn, query, desc = m[1], m[2], m[3], m[4]
            vim.keymap.set({ "n", "x", "o" }, lhs, function()
                fn(query, "textobjects")
            end, { desc = desc })
        end

        -- Swap the parameter under the cursor with the next/previous one.
        -- NOTE: <leader>r, not the upstream docs' <leader>a/<leader>A - those belong to
        -- harpoon here, and <leader>m* is multicursor.
        vim.keymap.set("n", "<leader>ra", function()
            swap.swap_next("@parameter.inner", "textobjects")
        end, { desc = "Swap parameter with next" })
        vim.keymap.set("n", "<leader>rA", function()
            swap.swap_previous("@parameter.inner", "textobjects")
        end, { desc = "Swap parameter with previous" })
    end,
}
