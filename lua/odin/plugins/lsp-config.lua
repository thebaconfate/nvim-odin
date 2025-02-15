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
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                typescript = { "prettierd", "prettier", stop_after_first = true },
                python = { "ruff_format" },
                javascript = { "prettierd", "prettier", stop_after_first = true },
                java = { "astyle" },
                latex = { "latexindent" },
                c = { "clang_format" },
                -- racket = { "raco_fmt" } -- Disable when working on R5RS or other dialects that turn brackets to square brackets
                haskell = { "ormulu" },
                erlang = {}
            },
            default_format_opts = {
                lsp_format = "fallback"
            },
            format_on_save = {
            },
            notify_no_formatter = true,
            formatters = {
                raco_fmt = {
                    command = "raco",
                    args = { "fmt", "$FILENAME" },
                    stdin = true,
                }
            }
        })
        local cmp = require("cmp")
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup({
            PATH = "prepend",                                -- Ensures Mason binaries are found first
            log_level = vim.log.levels.DEBUG,
            shell = "C:\\Program Files\\Git\\bin\\bash.exe", -- Use Git Bash
        }
        )
        require("mason-lspconfig").setup({
            ensure_installed = {
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
                "hls",
                "erlangls", -- NOTE: Installation and updates of erlangls are required to be exectuted in bash, otherwise it won't succeed. Simply run neovim in git bash if on windows
            },
            handlers = {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities,
                    })
                end,

                -- Config for Zig
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

                -- Config for Lua
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

                -- Configuration for Python
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

                -- Configuration for HTML
                ["html"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.html.setup({
                        capabilities = capabilities,
                        configurationSection = { "html", "css", "javascript" },
                        embeddedLanguages = {
                            css = true,
                            javascript = true
                        },
                    })
                end,

                -- Configuration for Astro
                ["astro"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.astro.setup({
                        capabilities = capabilities,
                    })
                end,


                -- Configuration for Typescript
                ["ts_ls"] = function()
                    require("lspconfig").ts_ls.setup({
                        capabilities = capabilities,
                    })
                end,

                -- Configuration for Java
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
                                    -- Kubernetes files will only be recognized if they're in a k8s directory. Otherwise it clashes with other yaml schemas
                                    kubernetes = "/k8s/*.yaml",
                                },

                                validate = true,   -- Enable YAML validation
                                completion = true, -- Enable autocompletion
                                hover = true,      -- Enable hover documentation
                            },
                        },
                    })
                end,

                -- Configuration for LaTeX
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
                                    async = true,
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

                -- Configuration for Dockerfiles
                ["dockerls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.dockerls.setup({
                        capabilities = capabilities,
                    })
                end,

                -- Configuration for docker_compose files
                ["docker_compose_language_service"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.docker_compose_language_service.setup({
                        capabilities = capabilities,
                    })
                end,

                -- Configuration for Haskell
                ["hls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.hls.setup({
                        filetypes = { 'haskell', 'lhaskell', 'cabal' },
                    })
                end,

                ["erlangls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.erlangls.setup({})
                end
            },
        })

        local lspconfig = require("lspconfig")
        lspconfig.racket_langserver.setup({
            capabilities = capabilities,
            cmd = { "racket", "-l", "racket-langserver" },
            filetypes = { "racket" },
            root_dir = lspconfig.util.root_pattern("*.rkt", ".git"),
            single_file_support = true,
            on_attach = function(client, bufnr)
                -- Optional: Auto-format on save
                if client.server_capabilities.documentFormattingProvider then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format()
                        end,
                    })
                end
            end,
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
                { name = "buffer" },
                { name = 'path' }
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
