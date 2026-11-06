-- The LSP servers to install and enable, by their lspconfig names. Shared by lsp-config.lua
-- (installs them through mason-lspconfig, then enables them) and mason-tool-installer.lua
-- (so :MasonToolsUpdate, and with it install.sh --update, upgrades them too: mason-lspconfig
-- only installs what's missing, it never updates).
return {
    "lua_ls",
    "astro",
    "vtsls",
    "oxlint",
    "html",
    "cssls",
    "yamlls",
    "texlab",
    "pyrefly",
    "ruff",
    "dockerls",
    "docker_compose_language_service",
    "jsonls",
    "bashls",
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
