-- The LSP servers to install and enable, by their lspconfig names. Shared by lsp-config.lua
-- (installs them through mason-lspconfig, then enables them) and mason-tool-installer.lua
-- (so :MasonToolsUpdate, and with it install.sh --update, upgrades them too: mason-lspconfig
-- only installs what's missing, it never updates).
return {
    "lua_ls",
    "astro",
    -- vtsls wraps the same tsserver but reimplements the VS Code extension
    -- layer, so inlay hints / organizeImports / "move to file" actually work.
    "vtsls",
    -- oxlint (oxc): lspconfig prefers the project-local node_modules/.bin/oxlint
    -- and roots on .oxlintrc.json, so it stays quiet in projects that do not use it.
    "oxlint",
    "html",
    "cssls",
    "yamlls",
    "texlab",
    -- EXPERIMENT (branch try-pyrefly): pyrefly instead of basedpyright.
    -- Measured on a large Django project, first completion in a file:
    --   basedpyright 1353ms -> 219ms -> 2ms      pyrefly 318ms -> 1ms -> 1ms
    -- Same capabilities; pyrefly returns 16 fewer items, all dunders.
    -- pyrefly does NOT read pyrightconfig.json, so the Django false-positive
    -- suppressions live in a local pyrefly.toml.
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
