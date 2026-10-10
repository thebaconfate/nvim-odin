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
        -- .oxfmtrc.json; require_cwd below means it is skipped everywhere else and
        -- prettier takes over. oxfmt does not handle css/html/markdown, so those
        -- stay on prettier unconditionally.
        local js_config = { "oxfmt", "prettierd", "prettier", stop_after_first = true }

        -- Resolve a Python tool from the project's own virtualenv before falling back
        -- to Mason/$PATH.
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
                python = { "ruff_format" },
                -- python = { "isort", "black" },
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
                ruff_format = { command = from_venv("ruff_format") },
                oxfmt = {
                    -- Only run where the project actually uses oxfmt: conform's bundled
                    -- config anchors cwd to .oxfmtrc.json, and require_cwd makes a miss
                    -- skip the formatter instead of running it with the wrong settings.
                    -- The binary resolves from the project's node_modules/.bin.
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
