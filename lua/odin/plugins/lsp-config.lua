return {
    "neovim/nvim-lspconfig",
    dependencies = {
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
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                --"rust_analyzer",
                --"gopls",
                "jdtls",
                "astro",
                "ts_ls",
                "html",
                "yamlls",
                "texlab",
                "pyright",
                "dockerls",
                "docker_compose_language_service",
            },
            handlers = {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities,
                        on_attach = function(client, bufnr)
                            -- Added: Auto-format on save setup
                            if client.server_capabilities.documentFormattingProvider then
                                vim.api.nvim_create_autocmd("BufWritePre", {
                                    group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
                                    buffer = bufnr,
                                    callback = function()
                                        if vim.bo.filetype == "python" then
                                            -- Use ruff for Python files
                                            vim.lsp.buf.format({
                                                async = false,
                                                filter = function(formatter)
                                                    return formatter.name == "ruff"
                                                end,
                                            })
                                        else
                                            -- Use the default formatter for other languages
                                            vim.lsp.buf.format({ async = false })
                                        end
                                    end,
                                })
                            else
                                local message = server_name + " " + "does not support formatting"
                                print(message)
                            end
                        end,
                    })
                end,

                zls = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.zls.setup({
                        root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
                        settings = {
                            zls = {
                                enable_inlay_hints = true,
                                enable_snippets = true,
                                warn_style = true,
                            },
                        },
                    })
                    vim.g.zig_fmt_parse_errors = 0
                    vim.g.zig_fmt_autosave = 0
                end,
                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                                },
                            },
                        },
                    })
                end,

                -- Pyright configuration for Python
                ["pyright"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.pyright.setup({
                        capabilities = capabilities,
                        settings = {
                            python = {
                                analysis = {
                                    typeCheckingMode = "basic", -- Type checking mode
                                    autoSearchPaths = true,     -- Automatically search for dependencies
                                    useLibraryCodeForTypes = true,
                                },
                            },
                        },
                    })
                end,

                ["astro"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.astro.setup({
                        capabilities = capabilities,
                    })
                end,
                ["ts_ls"] = function()
                    require("lspconfig").ts_ls.setup({
                        capabilities = capabilities,
                    })
                end,
                ["jdtls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.jdtls.setup({
                        capabilities = capabilities,
                    })
                end,
                -- YAML Language Server Setup
                ["yamlls"] = function()
                    require("lspconfig").yamlls.setup({
                        capabilities = capabilities,
                        settings = {
                            yaml = {
                                schemas = {
                                    -- Add GitHub Actions schema for workflows
                                    ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                                    ["https://raw.githubusercontent.com/yaml/yaml-language-server/master/src/schema/kubernetes-schema.json"] =
                                    -- Add K8s schema for kubernetes
                                    "/**/*.yaml",

                                },
                                validate = true,   -- Enable YAML validation
                                completion = true, -- Enable autocompletion
                                hover = true,      -- Enable hover documentation
                            },
                        },
                    })
                end,

                ["texlab"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.texlab.setup({
                        capabilities = capabilities,
                        settings = {
                            texlab = {
                                build = {
                                    executable = "latexmk", -- You can change this to pdflatex, xelatex, etc.
                                    args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                                    onSave = true,          -- Auto-build on save
                                },
                                viewer = {
                                    forwardSearch = true, -- Enable forward search
                                },
                                diagnostics = {
                                    enabled = true, -- Enable LaTeX diagnostics
                                },
                            },
                        },
                    })
                end,

                -- Dockerfile LSP (dockerls)
                ["dockerls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.dockerls.setup({
                        capabilities = capabilities,
                    })
                end,

                -- Compose Language Service LSP (docker_compose_language_service)
                ["docker_compose_language_service"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.docker_compose_language_service.setup({
                        capabilities = capabilities,
                    })
                end,
            },
        })

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
            }, {
                { name = "buffer" },
            }),
        })

        vim.diagnostic.config({
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
