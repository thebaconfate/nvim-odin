return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end,
            desc = "Format file using Conform",
        },
    },
    config = function()
        local prettier_config = { "prettierd", "prettier", stop_after_first = true }
        -- JS/TS only. oxfmt (the oxc formatter) is used by repos that ship an
        -- .oxfmtrc.json; require_cwd below means it is skipped everywhere else.
        -- Next, eslint_d covers projects whose Prettier options live inside the ESLint
        -- config (eslint-plugin-prettier, e.g. the backend's data-fetcher-shaper):
        -- plain prettier finds no .prettierrc there and rewraps at 80 columns.
        -- Projects with neither fall through to prettier. oxfmt does not handle
        -- css/html/markdown, so those stay on prettier unconditionally.
        local js_config = { "oxfmt", "eslint_d", "prettierd", "prettier", stop_after_first = true }

        -- Resolve a Python tool from the project's own virtualenv before falling back
        -- to Mason/$PATH. Projects pin their black version, and a newer black reformats
        -- differently - running the wrong one means fighting CI.
        local function from_venv(tool)
            return function(_, ctx)
                for dir in vim.fs.parents(ctx.filename) do
                    for _, venv in ipairs({ "venv", ".venv", "env" }) do
                        local bin = vim.fs.joinpath(dir, venv, "bin", tool)
                        if vim.fn.executable(bin) == 1 then
                            return bin
                        end
                    end
                end
                return tool
            end
        end
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                typescript = js_config,
                typescriptreact = js_config,
                javascript = js_config,
                javascriptreact = js_config,
                -- ruff_format is parked, not deleted - uncomment and drop the line
                -- below to go back to it.
                -- python = { "ruff_format" },
                --
                -- black reads [tool.black] from the REPO-ROOT pyproject.toml when nested
                -- ones lack it (it finds the root via the .git dir). isort orders imports
                -- (profile=black, sections in setup.cfg) and CI can enforce that order
                -- through the flake8-isort plugin. isort runs first; profile=black keeps
                -- them in agreement.
                python = { "isort", "black" },
                astro = prettier_config,
                css = prettier_config,
                html = prettier_config,
                markdown = prettier_config,
                java = { "astyle" },
                latex = { "latexindent" },
                c = { "clang_format" },
                -- racket = { "raco_fmt" } -- Disable when working on R5RS or other dialects that turn brackets to square brackets
                haskell = { "ormolu" },
                erlang = { "erlfmt" },
                clojure = { "cljfmt" },
                lisp = { "cl_identify" },
            },
            default_format_opts = {
                lsp_format = "fallback",
            },
            format_on_save = {},
            -- Saving a filetype with no matching tool used to print a warning on every
            -- write. Errors are still reported; only the "no formatter" notice is muted.
            notify_no_formatter = false,
            formatters = {
                black = { command = from_venv("black") },
                isort = { command = from_venv("isort") },
                ruff_format = { command = from_venv("ruff") },
                oxfmt = {
                    -- Only run where the project actually uses oxfmt: conform's bundled
                    -- config anchors cwd to .oxfmtrc.json, and require_cwd makes a miss
                    -- skip the formatter instead of running it with the wrong settings.
                    -- The binary resolves from the project's node_modules/.bin.
                    require_cwd = true,
                },
                eslint_d = {
                    -- conform's bundled config anchors cwd to package.json, which every JS
                    -- project has. Anchor to an ESLint config instead, so projects without
                    -- ESLint skip it and fall through to prettier.
                    cwd = require("conform.util").root_file({
                        ".eslintrc",
                        ".eslintrc.js",
                        ".eslintrc.cjs",
                        ".eslintrc.json",
                        ".eslintrc.yaml",
                        ".eslintrc.yml",
                        "eslint.config.js",
                        "eslint.config.mjs",
                        "eslint.config.cjs",
                        "eslint.config.ts",
                    }),
                    require_cwd = true,
                },
                raco_fmt = {
                    command = "raco",
                    args = { "fmt", "$FILENAME" },
                    stdin = true,
                },
                cl_identify = {
                    command = "sbcl",
                    args = {
                        "--noinform",
                        "--non-interactive",
                        "--eval",
                        [[(progn
                            (ql:quickload :cl-indentify :silent t)
                            (uiop:symbol-call :indentify :indentify *standard-input* *standard-output*))]],
                        "--quit",
                    },
                    stdin = true,
                },
            },
        })
    end,
}
