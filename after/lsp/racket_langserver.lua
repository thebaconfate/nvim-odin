return {
    cmd = { "racket", "-l", "racket-langserver" },
    filetypes = { "racket" },
    -- NOTE: `root_markers` (plural) is the vim.lsp.Config key; `root_marker` was silently ignored.
    -- Markers are exact file names, not globs: "*.rkt" never matched anything. info.rkt
    -- marks the top of a Racket package/collection, so it roots projects outside git too.
    root_markers = { "info.rkt", ".git" },
    -- NOTE: formatting on save is handled by conform (see lua/odin/plugins/conform.lua),
    -- which falls back to the LSP. Registering a BufWritePre hook here formatted twice.
}
