vim.o.number = true
vim.o.relativenumber = true

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.wrap = true

vim.o.swapfile = false
vim.o.backup = false
-- With swapfile and backup off, undofile is the only recovery left. It also keeps
-- undo history across sessions. Stored under stdpath("state")/undo.
vim.o.undofile = true

vim.o.hlsearch = false
vim.o.incsearch = true
-- Case-insensitive search, unless the pattern contains a capital letter.
vim.o.ignorecase = true
vim.o.smartcase = true

-- NOTE: termguicolors is on by default in 0.10+ when the terminal supports it.
-- winborder (0.11+) gives every floating window a border, so plugins and the
-- built-in LSP/diagnostic floats no longer each need their own `border` option.
vim.o.winborder = "single"

vim.o.scrolloff = 8
vim.o.signcolumn = "yes"

vim.o.updatetime = 50
-- A visual guide rather than a global textwidth: textwidth=80 auto-wrapped as you
-- typed in any filetype whose formatoptions includes 't' (python, markdown), while
-- leaving lua alone. Prose filetypes opt in explicitly below.
vim.o.colorcolumn = "80"

-- Treesitter-aware folding. Neovim already sets this foldexpr in a few bundled
-- ftplugins (e.g. ftplugin/lua.lua) but leaves foldmethod at "manual", so it never
-- took effect. foldlevelstart=99 opens files unfolded; without it every buffer
-- would open fully collapsed.
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("odin_prose_textwidth", { clear = true }),
    -- gitcommit is left out: Neovim's own ftplugin already wraps it at git's 72.
    pattern = { "markdown", "tex", "plaintex", "text" },
    callback = function()
        vim.opt_local.textwidth = 80
    end,
    desc = "Hard-wrap prose filetypes at 80 columns",
})

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
