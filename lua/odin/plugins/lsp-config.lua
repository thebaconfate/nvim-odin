return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "stevearc/conform.nvim",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
    },
    config = function()
        local cmp = require("cmp")

        local function get_shell()
            local sys_bash = "C:\\windows\\system32\\bash.exe"
            local git_bash = "C:\\Program Files\\Git\\bin\\bash.exe" -- Use Git Bash
            if vim.loop.fs_stat(sys_bash) then
                return sys_bash
            elseif vim.loop.fs_stat(git_bash) then
                return git_bash
            else
                return nil
            end
        end
        require("fidget").setup({})
        require("mason").setup({
            PATH = "prepend", -- Ensures Mason binaries are found first
            log_level = vim.log.levels.DEBUG,
            shell = get_shell()

        })
        local servers = {
            "lua_ls",
            --"rust_analyzer",
            --"gopls",
            "jdtls",
            "astro",
            "ts_ls",
            "html",
            "cssls",
            "yamlls",
            "texlab",
            "pyright",
            "clangd",
            "dockerls",
            "docker_compose_language_service",
            -- "hls",
            -- "erlangls",
            -- NOTE: Installation and updates of erlangls are required to be exectuted in bash, otherwise it won't succeed.
            -- Simply run neovim in git bash or wsl bash if on windows

            -- "opencl_ls"
        }
        require("mason-lspconfig").setup({
            ensure_installed = servers,
        })

        for _, server in ipairs(servers) do
            vim.lsp.config(server, {})
            vim.lsp.enable(server)
        end

        vim.lsp.enable('racket_langserver')
        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                ["<Tab>"] = cmp.mapping.confirm({ select = true }),
                ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" }, -- For luasnip users.
                { name = "buffer" },
                { name = 'path' }
            }),

        })

        vim.diagnostic.config({
            virtual_lines = true,
            update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end,
}
