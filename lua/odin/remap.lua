vim.keymap.set("n", "<leader>pv", ":NvimTreeFindFile<CR>")
vim.keymap.set("n", "<leader>f", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { noremap = true, silent = true, desc = "Format file using Conform" })

-- Disables Q (Ex mode), this prevents accidental execution of recorded macros
vim.keymap.set("n", "Q", "<nop>")

-- Moves the highlighted line down by one
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- Moves the highlighted line up by one
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Yanks the highlighted text into the system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
-- Yanks the current line into the system clipboard
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Deletes the selection or motion into the void register, prevents overriding the default register when using motions
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Goes to the next identical word under the cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Re-sources the config
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

vim.keymap.set("n", "<leader>zm", ":ZenMode<CR>")
