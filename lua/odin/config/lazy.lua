-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.fn.isdirectory(lazypath) == 1) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- lazy.nvim opens the float that dims the screen behind :Lazy without a `border`, so
-- winborder (set.lua) would frame the whole screen: take it off again
vim.api.nvim_create_autocmd("FileType", {
    pattern = "lazy_backdrop",
    callback = function(args)
        vim.api.nvim_win_set_config(vim.fn.bufwinid(args.buf), { border = "none" })
    end,
})

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "odin.plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- No border on the :Lazy window (ui.border stays "none"): the window stands out from the
    -- dimmed screen on its own, and a border line, drawn mid-cell, would leave a strip of the
    -- window's color outside it.
    -- Checking for updates on every start costs a GitHub round trip and produces
    -- notifications you did not ask for; run :Lazy check when you want to know.
    checker = { enabled = false },
    -- No plugin here needs luarocks, and leaving it on makes :checkhealth report an
    -- error about a missing hererocks install.
    rocks = { enabled = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
                -- oil.nvim is the file explorer (default_file_explorer = true)
                "netrwPlugin",
            },
        },
    },
})
