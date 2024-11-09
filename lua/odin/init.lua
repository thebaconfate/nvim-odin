require("odin.set")
require("odin.remap")
require("odin.config.lazy")

vim.api.nvim_create_autocmd({ "BufWritePre" },
    {
        pattern = '*',
        command = [[%s/\s\+$//e]],
    })

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.tex",
    command = "silent !latexmk -pdf %"
})
