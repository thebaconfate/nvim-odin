return {
    -- nvim-metals
    "scalameta/nvim-metals",
    name = "metals",
    ft = { "scala", "sbt" },
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "j-hui/fidget.nvim",
            opts = {},
        },
    },
    opts = function()
        local metals_config = require("metals").bare_config()
        metals_config.settings = {
            showImplicitArguments = true,
        }
        metals_config.init_options.statusBarProvider = "off"
        metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()
        metals_config.on_attach = function(client, bufnr)
            if client.name == "metals" then
                local map = vim.keymap.set
                map("n", "<leader>gd", vim.lsp.buf.definition)
                map("n", "<leader>gi", vim.lsp.buf.implementation)
                map("n", "K", vim.lsp.buf.hover)
                map("n", "<leader>vws", vim.lsp.buf.workspace_symbol)
                map("n", "<leader>vd", vim.lsp.diagnostic.open_float)
                map("n", "<leader>vca", vim.lsp.buf.code_action)
                map("n", "<leader>vrr", vim.lsp.buf.references)
                map("n", "<leader>vrn", vim.lsp.buf.rename)
                map("i", "<C-h>", vim.lsp.buf.signature_help)
                map("n", "nd", vim.lsp.diagnostic.goto_next)
                map("n", "Nd", vim.lsp.diagnostic.goto_prev)
            end
        end
        return metals_config
    end,
    config = function(self, metals_config)
        local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = self.ft,
            callback = function()
                require("metals").initialize_or_attach(metals_config)
            end,
            group = nvim_metals_group,
        })
    end

}
