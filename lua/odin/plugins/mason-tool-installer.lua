return {
    -- mason-lspconfig only handles LSP servers; the conform formatters have to be
    -- requested separately or every save falls back to the LSP (or does nothing).
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    cmd = { 'MasonToolsInstall', 'MasonToolsUpdate' },
    event = 'VeryLazy',
    opts = {
        ensure_installed = {
            'stylua',        -- lua
            'prettierd',     -- ts/js/astro/css/html/markdown
            'prettier',      -- fallback when prettierd is unavailable
            'ruff',          -- python: ruff LSP (linting). ruff_format is currently
            --                  parked in conform.lua in favour of black/isort.
            'black',         -- python formatter; projects with their own venv copy win
            'isort',         -- python import sorting (see conform.lua)
            'clang-format',  -- c
            'latexindent',   -- latex
            'ormolu',        -- haskell
            'cljfmt',        -- clojure
            -- jdtls is driven by nvim-jdtls rather than mason-lspconfig, so it has
            -- to be requested here instead of via the servers list.
            'jdtls',
            -- NOTE: not in the Mason registry; these come from the system or the
            -- language toolchain:
            --   astyle  (java)    -> brew install astyle, or switch conform's java
            --                        entry to google-java-format, which Mason does have
            --   erlfmt  (erlang)  -> rebar3 / hex
            --   sbcl    (lisp)    -> brew install sbcl
            --   raco    (racket)  -> ships with DrRacket
        },
        run_on_start = false, -- Install on demand via :MasonToolsInstall, not every startup
    },
}
