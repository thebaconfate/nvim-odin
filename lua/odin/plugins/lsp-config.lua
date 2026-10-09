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

        -- Neovim 0.11+ already maps grn (rename), gra (code action), grr (references),
        -- gri (implementation), gO (document symbol), K (hover), <C-s> (signature help)
        -- and ]d / [d (diagnostic jump). Only the additions worth having are set here.
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("odin_lsp_attach", { clear = true }),
            callback = function(ev)
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
                end

                -- Inlay hints are configured per-server (see after/lsp/vtsls.lua) but are off by
                -- default: Neovim re-requests them after every keystroke, and in ~/dev/qargo/frontend
                -- tsc/vtsls take 1-2s per request, queueing in front of completions (measured typing
                -- a line there: completion median 75-170ms with hints, 41-50ms without).
                -- Show them per buffer when wanted.
                map("n", "<leader>vih", function()
                    vim.lsp.inlay_hint.enable(
                        not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                        { bufnr = ev.buf }
                    )
                end, "LSP: toggle inlay hints")

                -- Picker-backed variants of the built-in jumps (snacks.picker): these give a
                -- picker instead of the quickfix list, which is why they override the
                -- defaults. They take over the gr* keys rather than claiming new ones, so
                -- built-in `gi` (resume insert where you last left it) stays available.
                map("n", "gd", function() Snacks.picker.lsp_definitions() end, "LSP: definitions (picker)")
                map("n", "gri", function() Snacks.picker.lsp_implementations() end, "LSP: implementations (picker)")
                map("n", "grr", function() Snacks.picker.lsp_references() end, "LSP: references (picker)")
                map("n", "<leader>vws", function() Snacks.picker.lsp_workspace_symbols() end, "LSP: workspace symbols (picker)")

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
            desc = "Buffer-local LSP keymaps",
        })

        -- Per-server settings live in after/lsp/<server>.lua and are picked up automatically.
        -- They must sit in after/ rather than lsp/: Neovim merges every lsp/<name>.lua on the
        -- runtimepath with "force" and the LAST one wins, so a plain lsp/ dir would be
        -- overridden by nvim-lspconfig's bundled defaults. See :h lsp-config.
        vim.lsp.enable(servers)
        vim.lsp.enable("racket_langserver")
        -- EXPERIMENT (branch try-tsc): TypeScript 7's native `tsc --lsp` in projects on
        -- TS 7+, vtsls everywhere else (lua/odin/typescript.lua decides). Enabled outside
        -- `servers` because it is not a Mason package: it runs the project's own compiler.
        -- Measured on ~/dev/qargo/frontend (TS 7.0.2, vtsls bundles 5.9.3), 3 runs on
        -- MetricOverrideTableField.tsx:
        --   first non-empty completion after open   vtsls 6.4-7.1s    tsc 0.7-1.0s
        --   hover once loaded                       vtsls ~460ms      tsc ~150ms
        -- Same completion items, same capabilities; tsc also advertises willRenameFiles.
        -- Delete this line to go back to vtsls everywhere.
        vim.lsp.enable("tsc")

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
