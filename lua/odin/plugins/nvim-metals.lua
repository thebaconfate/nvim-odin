return {
    -- nvim-metals
    "scalameta/nvim-metals",
    name = "metals",
    ft = { "scala", "sbt" },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    -- stylua: ignore
    keys = {
        { "<leader>cW", function () require('metals').hover_worksheet() end, desc = "Metals Worksheet" },
        { "<leader>cM", function () require('telescope').extensions.metals.commands() end, desc = "Telescope Metals Commands" },
    },
    config = function()
        local metals_config = require("metals").bare_config()

        metals_config.settings = {
            showImplicitArguments = true,
            showImplicitConversionsAndClasses = true,
            showInferredType = true,
            superMethodLensesEnabled = true,
        }
        metals_config.init_options.statusBarProvider = "on"
        metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

        local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "scala", "sbt" },
            callback = function()
                require("metals").initialize_or_attach(metals_config)
            end,
            group = nvim_metals_group,
        })
    end,
}
