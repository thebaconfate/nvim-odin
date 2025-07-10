return {
    settings = {
        texlab = {
            build = {
                executable = "latexmk", -- You can change this to pdflatex, xelatex, etc.
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
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
