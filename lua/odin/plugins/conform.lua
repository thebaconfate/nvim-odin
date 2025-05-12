return {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
        local prettier_config = { "prettierd", "prettier", stop_after_first = true }
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                typescript = prettier_config,
                python = { "ruff_format" },
                javascript = prettier_config,
                astro = prettier_config,
                css = prettier_config,
                html = prettier_config,
                markdown = prettier_config,
                java = { "astyle" },
                latex = { "latexindent" },
                c = { "clang_format" },
                -- racket = { "raco_fmt" } -- Disable when working on R5RS or other dialects that turn brackets to square brackets
                haskell = { "ormulu" },
                erlang = { "erlfmt" },
                clojure = { "cljfmt" }
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
    end
}
