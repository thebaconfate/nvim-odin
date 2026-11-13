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

-- Indent guide colors per level: rainbow-delimiters' (the theme sets them), in its order.
-- The guides get them faded into the background, the current block's guide the full color.
local rainbow = { "Red", "Yellow", "Blue", "Orange", "Green", "Violet", "Cyan" }
local FADE = 0.35 -- how much of the color is left; the rest is the background

local function rainbow_guides()
    local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or 0
    for i, color in ipairs(rainbow) do
        local fg = vim.api.nvim_get_hl(0, { name = "RainbowDelimiter" .. color, link = false }).fg
        if fg then
            local mixed = 0
            for shift = 0, 16, 8 do -- blue, green, red
                local a = bit.band(bit.rshift(fg, shift), 0xff)
                local b = bit.band(bit.rshift(bg, shift), 0xff)
                mixed = mixed + bit.lshift(math.floor(b + (a - b) * FADE + 0.5), shift)
            end
            vim.api.nvim_set_hl(0, "SnacksIndentRainbow" .. i, { fg = mixed })
        else -- a theme without rainbow colors: plain grey guides
            vim.api.nvim_set_hl(0, "SnacksIndentRainbow" .. i, { link = "SnacksIndent" })
        end
    end
end

local function claude_code_split()
    Snacks.terminal.toggle("claude", { win = { position = "right", width = 0.4 } })
end

local function claude_code_tab()
    vim.cmd("tabnew")
    Snacks.terminal.open("claude", { win = { position = "current" } })
end

local function hl_groups(prefix, names)
    return vim.tbl_map(function(name)
        return prefix .. name
    end, names)
end

return {
    -- Only the picker and indent guides: snacks enables just the modules listed in opts.
    -- (Snacks.terminal, for the Claude split, works without being listed.)
    "folke/snacks.nvim",
    -- Loaded at startup, as snacks asks: plugins that hook into it (todo-comments' picker
    -- source) only register if Snacks exists by the time they load.
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
        -- Runs before any plugin loads, so it catches the theme's own :colorscheme at startup
        vim.api.nvim_create_autocmd("ColorScheme", { callback = rainbow_guides })
    end,
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
        {
            "<leader>ps",
            grep(function()
                return vim.fn.input("Grep > ")
            end),
            desc = "Picker: grep prompt",
        },
        { "<leader>cc", claude_code_split, desc = "Claude Code: toggle split" },
        { "<leader>cC", claude_code_tab, desc = "Claude Code: full-screen tab" },
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
        -- Indent guides, like VSCode's: a line per indent level, and a brighter one for the
        -- block the cursor is in. VSCode doesn't animate that one, so neither does this.
        -- Colored per level, see rainbow_guides() above.
        indent = {
            indent = { hl = hl_groups("SnacksIndentRainbow", { 1, 2, 3, 4, 5, 6, 7 }) },
            scope = { hl = hl_groups("RainbowDelimiter", rainbow) },
            animate = { enabled = false },
        },
    },
}
