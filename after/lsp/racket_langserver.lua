return {
    cmd = { "racket", "-l", "racket-langserver" },
    filetypes = { "racket" },
    -- NOTE: `root_markers` (plural) is the vim.lsp.Config key; `root_marker` was silently ignored.
    root_markers = { "*.rkt", ".git" },
    -- NOTE: formatting on save is handled by conform (see lua/odin/plugins/conform.lua),
    -- which falls back to the LSP. Registering a BufWritePre hook here formatted twice.
}
