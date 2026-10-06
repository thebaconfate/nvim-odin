require("odin.set")
require("odin.remap")
require("odin.config.lazy")

-- Strip trailing whitespace on save. Done in Lua rather than `:%s/\s\+$//e` so it
-- leaves the cursor position, the jumplist and the search register (@/) untouched.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("odin_strip_whitespace", { clear = true }),
    pattern = "*",
    callback = function(args)
        local view = vim.fn.winsaveview()
        vim.api.nvim_buf_call(args.buf, function()
            vim.cmd([[keeppatterns keepjumps silent! %s/\s\+$//e]])
        end)
        vim.fn.winrestview(view)
    end,
    desc = "Strip trailing whitespace on save",
})

vim.filetype.add({
    extension = {
        cl = "opencl",
    },
})
