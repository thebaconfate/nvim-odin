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
        -- metals attaches via initialize_or_attach, so it does not inherit the capabilities
        -- blink.cmp registers on vim.lsp.config("*"); set them explicitly here.
        local ok, blink = pcall(require, "blink.cmp")
        metals_config.capabilities = ok and blink.get_lsp_capabilities()
            or vim.lsp.protocol.make_client_capabilities()
        metals_config.on_attach = function(_, _)
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
