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
    -- automatically check for plugin updates
    checker = { enabled = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client ~= nil and client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autoTrigger = true })
        end
        local opts = {
            buffer = ev.buf,
        }

        vim.keymap.set("n", "gd", function()
            require("telescope.builtin").lsp_definitions()
        end, opts)
        vim.keymap.set("n", "gi", function()
            require("telescope.builtin").lsp_implementations()
        end, opts)
        vim.keymap.set("n", "<leader>vrr", function()
            require("telescope.builtin").lsp_references()
        end, opts)
        vim.keymap.set("n", "<leader>vws", function()
            require("telescope.builtin").lsp_workspace_symbols()
        end, opts)
        vim.keymap.set("n", "gD", function()
            vim.lsp.buf.declaration()
        end, opts)

        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

        vim.keymap.set("n", "nd", function()
            vim.diagnostic.jump({ count = 1, float = true })
        end, opts)
        vim.keymap.set("n", "Nd", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, opts)
        vim.keymap.set("n", "<leader>cvd", function()
            local diag = vim.diagnostic.get(ev.buf, { lnum = vim.fn.line('.') - 1 })
            if #diag > 0 then
                local msg = ""
                for _, d in ipairs(diag) do
                    msg = msg .. d.message .. "\n"
                end
                vim.fn.setreg('+', msg)
                print("Diagnostic copied to clipboard")
            else
                print("No diagnostic found on this line")
            end
        end, opts)
    end,
})
