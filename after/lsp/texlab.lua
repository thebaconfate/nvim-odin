return {
    settings = {
        texlab = {
            build = {
                executable = "latexmk", -- You can change this to pdflatex, xelatex, etc.
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                -- NOTE: this is the only build-on-save hook. A BufWritePost `:!latexmk`
                -- autocmd used to run alongside it: it blocked the UI, raced this build
                -- on the same .aux/.pdf, and compiled \input'd subfiles on their own.
                onSave = true,          -- Auto-build on save
                async = true,
            },
            viewer = {
                forwardSearch = true, -- Enable forward search
            },
            diagnostics = {
                enabled = true, -- Enable LaTeX diagnostics
            },
        },
    },
}
