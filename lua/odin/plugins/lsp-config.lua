return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "stevearc/conform.nvim",
        -- NOTE: mason moved org from williamboman/* to mason-org/* with v2.
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "j-hui/fidget.nvim",
        "saghen/blink.cmp",
    },
    config = function()
        local function file_exists(path)
            return vim.fn.filereadable(path) == 1
        end

        local function get_shell()
            if vim.fn.has("win32") == 0 then
                -- Native unix, return the shell
                return vim.env.SHELL or "/bin/bash"
            end
            local git_bash = "C:\\Program Files\\Git\\bin\\bash.exe" -- Use Git Bash
            local wingw64 = "C:\\msys64\\mingw64.exe"
            if file_exists(wingw64) then
                return wingw64
            elseif file_exists(git_bash) then
                vim.notify("No msys64 found, defaulting to git bash as shell. Please install msys64 for future use")
                return git_bash
            else
                vim.notify("No Bash found! Some features may not work.", vim.log.levels.WARN)
                return nil
            end
        end

        require("fidget").setup({})
        require("mason").setup({
            PATH = "prepend", -- Ensures Mason binaries are found first
            shell = get_shell(),
        })

        local servers = {
            "lua_ls",
            "astro",
            -- vtsls wraps the same tsserver but reimplements the VS Code extension
            -- layer, so inlay hints / organizeImports / "move to file" actually work.
            "vtsls",
            -- oxlint (oxc) is the linter in the qargo frontend. lspconfig prefers the
            -- project-local node_modules/.bin/oxlint and roots on .oxlintrc.json, so it
            -- stays quiet in projects that do not use it.
            "oxlint",
            "html",
            "cssls",
            "yamlls",
            "texlab",
            -- EXPERIMENT (branch try-pyrefly): pyrefly instead of basedpyright.
            -- Measured on ~/dev/qargo/backend/projects/tms, first completion in a file:
            --   basedpyright 1353ms -> 219ms -> 2ms      pyrefly 318ms -> 1ms -> 1ms
            -- Same capabilities; pyrefly returns 16 fewer items, all dunders.
            -- pyrefly does NOT read pyrightconfig.json, so the Django false-positive
            -- suppressions live in a local projects/tms/pyrefly.toml.
            -- Swap these two lines to go back.
            -- "basedpyright",
            "pyrefly",
            -- Types and hover come from the Python type checker; ruff adds linting and fix-alls.
            "ruff",
            "dockerls",
            "docker_compose_language_service",
            "jsonls",
            "bashls",
            -- NOTE: Installation and updates of erlangls are required to be exectuted in bash, otherwise it won't succeed.
            -- Simply run neovim in git bash or wsl bash if on windows
            --
            "clangd",
            "ltex_plus",
            "marksman", -- markdown: cross-file links, headings, rename
            -- "rust_analyzer",
            -- "gopls",
            -- "hls",
            -- "erlangls",
            -- "opencl_ls,"
            -- "elixirls"
        }

        require("mason-lspconfig").setup({
            ensure_installed = servers,
            -- We call vim.lsp.enable ourselves below; letting mason-lspconfig also enable
            -- every installed server would start servers we never asked for.
            automatic_enable = false,
        })

        -- NOTE: no vim.lsp.config("*", { capabilities = ... }) here. blink.cmp's own
        -- plugin/blink-cmp.lua already registers its capabilities for every server on
        -- 0.11+, which is why blink is a dependency above: it has to load first.

        -- Per-server settings live in after/lsp/<server>.lua and are picked up automatically.
        -- They must sit in after/ rather than lsp/: Neovim merges every lsp/<name>.lua on the
        -- runtimepath with "force" and the LAST one wins, so a plain lsp/ dir would be
        -- overridden by nvim-lspconfig's bundled defaults. See :h lsp-config.
        vim.lsp.enable(servers)
        vim.lsp.enable("racket_langserver")

        vim.diagnostic.config({
            -- Virtual lines are loud, so reserve them for things worth interrupting
            -- for. HINT-level notes (e.g. pyrefly's unused-parameter on callback
            -- signatures) still show in the sign column and on <leader>vd.
            virtual_lines = { severity = { min = vim.diagnostic.severity.WARN } },
            update_in_insert = false,
            float = {
                focusable = false,
                style = "minimal",
                source = true,
                header = "",
                prefix = "",
            },
        })
    end,
}
