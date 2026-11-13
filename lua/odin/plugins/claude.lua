-- Claude Code in a snacks terminal. A second spec for snacks.nvim: lazy.nvim merges it
-- with the one in snacks.lua (the keys lists are combined), so snacks still loads once.
-- Snacks.terminal works without being listed in snacks' opts.

local function claude_code_split()
    Snacks.terminal.toggle("claude", { win = { position = "right", width = 0.4 } })
end

local function claude_code_tab()
    vim.cmd("tabnew")
    Snacks.terminal.open("claude", { win = { position = "current" } })
end

return {
    "folke/snacks.nvim",
    keys = {
        { "<leader>cc", claude_code_split, desc = "Claude Code: toggle split" },
        { "<leader>cC", claude_code_tab, desc = "Claude Code: full-screen tab" },
    },
}
