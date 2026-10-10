local function pick(source, opts)
    return function()
        Snacks.picker[source](opts)
    end
end

-- Like telescope's grep_string: a literal search for `search`, then typing filters the hits.
-- (snacks' own grep_word only matches whole words, which telescope's didn't.)
local function grep(search)
    return function()
        Snacks.picker.grep({ search = search(), regex = false, live = false })
    end
end

-- Telescope's keys inside the picker, where snacks differs: <C-x> splits (snacks: <C-s>),
-- <C-u>/<C-d> scroll the preview (snacks: they scroll the list) and <M-q> sends the
-- selection to quickfix (snacks' <C-q> already does selected-else-all).
local telescope_keys = {
    ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
    ["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
    ["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
    ["<M-q>"] = { "qflist", mode = { "i", "n" } },
}

return {
    -- Only the picker: snacks enables just the modules listed in opts, the rest stay off.
    "folke/snacks.nvim",
    -- Loaded at startup, as snacks asks: plugins that hook into it (todo-comments' picker
    -- source) only register if Snacks exists by the time they load.
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<leader>pf", pick("files", { hidden = true }), desc = "Picker: find files" },
        { "<C-p>", pick("git_files"), desc = "Picker: git files" },
        { "<leader>vh", pick("help"), desc = "Picker: help tags" },
        {
            "<leader>pws",
            grep(function()
                return vim.fn.expand("<cword>")
            end),
            desc = "Picker: grep word under cursor",
        },
        {
            "<leader>pWs",
            grep(function()
                return vim.fn.expand("<cWORD>")
            end),
            desc = "Picker: grep WORD under cursor",
        },
        { "<leader>ps", grep(function()
            return vim.fn.input("Grep > ")
        end), desc = "Picker: grep prompt" },
    },
    opts = {
        picker = {
            prompt = "🔍 ",
            -- Prompt at the bottom, results above it, preview on the right. A fixed preset
            -- also stops snacks switching to a vertical layout in narrow windows.
            layout = { preset = "telescope" },
            formatters = { file = { truncate = "left" } }, -- like telescope's path_display truncate
            win = {
                input = { keys = telescope_keys },
                list = { keys = telescope_keys },
            },
        },
    },
}
