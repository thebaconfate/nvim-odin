return {
    cmd = { "racket", "-l", "racket-langserver" },
    filetypes = { "racket" },
    root_marker = { '*.rkt', ".git" },
    single_file_support = true,
    on_attach = function(client, bufnr)
        -- Optional: Auto-format on save
        if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format()
                end,
            })
        end
    end,
}
