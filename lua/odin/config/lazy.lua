-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.fn.isdirectory(lazypath) == 1) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "odin.plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- Checking for updates on every start costs a GitHub round trip and produces
    -- notifications you did not ask for; run :Lazy check when you want to know.
    checker = { enabled = false },
    -- No plugin here needs luarocks, and leaving it on makes :checkhealth report an
    -- error about a missing hererocks install.
    rocks = { enabled = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
                -- oil.nvim is the file explorer (default_file_explorer = true)
                "netrwPlugin",
            },
        },
    },
})

-- Neovim 0.11+ already maps grn (rename), gra (code action), grr (references),
-- gri (implementation), gO (document symbol), K (hover), <C-s> (signature help)
-- and ]d / [d (diagnostic jump). Only the additions worth having are set here.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
        end

        -- Inlay hints are configured per-server (see after/lsp/vtsls.lua) but render
        -- nothing until enabled here.
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
        map("n", "<leader>vih", function()
            vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                { bufnr = ev.buf }
            )
        end, "LSP: toggle inlay hints")

        -- Telescope-backed variants of the built-in jumps: these give a picker
        -- instead of the quickfix list, which is why they override the defaults.
        -- They take over the gr* keys rather than claiming new ones, so built-in
        -- `gi` (resume insert where you last left it) stays available.
        map("n", "gd", function()
            require("telescope.builtin").lsp_definitions()
        end, "LSP: definitions (Telescope)")
        map("n", "gri", function()
            require("telescope.builtin").lsp_implementations()
        end, "LSP: implementations (Telescope)")
        map("n", "grr", function()
            require("telescope.builtin").lsp_references()
        end, "LSP: references (Telescope)")
        map("n", "<leader>vws", function()
            require("telescope.builtin").lsp_workspace_symbols()
        end, "LSP: workspace symbols (Telescope)")

        map("n", "gD", vim.lsp.buf.declaration, "LSP: go to declaration")
        map("n", "<leader>vd", vim.diagnostic.open_float, "Diagnostics: show float")

        map("n", "nd", function()
            vim.diagnostic.jump({ count = 1, float = true })
        end, "Diagnostics: next")
        map("n", "Nd", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, "Diagnostics: previous")

        map("n", "<leader>cvd", function()
            local diag = vim.diagnostic.get(ev.buf, { lnum = vim.fn.line(".") - 1 })
            if #diag == 0 then
                vim.notify("No diagnostic found on this line", vim.log.levels.WARN)
                return
            end
            local msg = vim.iter(diag):map(function(d) return d.message end):join("\n")
            vim.fn.setreg("+", msg)
            vim.notify("Diagnostic copied to clipboard")
        end, "Diagnostics: copy line diagnostics to clipboard")
    end,
})
