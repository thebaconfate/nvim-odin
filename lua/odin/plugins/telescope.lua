local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

-- telescope-fzf-native needs `make`, which needs a bash-like shell. Unix has one;
-- on Windows we have to go looking. Kept free of vim.notify because this runs at
-- spec-load time, before the UI exists.
local function fzf_native_build()
    if vim.fn.has("win32") == 0 then
        return "make"
    end
    local wingw64 = "C:\\msys64\\mingw64.exe"
    local git_bash = "C:\\Program Files\\Git\\bin\\bash.exe"
    if file_exists(wingw64) then
        return wingw64 .. " -c make"
    elseif file_exists(git_bash) then
        return git_bash .. " -c make"
    end
    -- No bash found: skip the build rather than failing the install. Telescope still
    -- works, just without the native fzf sorter.
    return false
end

local function pick(name, opts)
    return function()
        require("telescope.builtin")[name](opts or {})
    end
end

return {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    keys = {
        { '<leader>pf', pick('find_files'),  desc = 'Telescope: find files' },
        { '<C-p>',      pick('git_files'),   desc = 'Telescope: git files' },
        { '<leader>vh', pick('help_tags'),   desc = 'Telescope: help tags' },
        {
            '<leader>pws',
            function() require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') }) end,
            desc = 'Telescope: grep word under cursor',
        },
        {
            '<leader>pWs',
            function() require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') }) end,
            desc = 'Telescope: grep WORD under cursor',
        },
        {
            '<leader>ps',
            function() require('telescope.builtin').grep_string({ search = vim.fn.input('Grep > ') }) end,
            desc = 'Telescope: grep prompt',
        },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',                                                          -- Required dependency
        'nvim-treesitter/nvim-treesitter',                                                -- Optional for better previewing
        'nvim-tree/nvim-web-devicons',                                                    -- Optional for file icons
        -- NOTE: `fd` and `rg` are external CLI binaries (install via your package manager),
        -- not Neovim plugins. Listing sharkdp/fd here made lazy clone the Rust source for
        -- nothing.
        { 'nvim-telescope/telescope-fzf-native.nvim', build = fzf_native_build() },       -- NOTE: Won't build on windows unless you use mingw64
    },
    config = function()
        require('telescope').setup({
            defaults = {
                vimgrep_arguments = {
                    'rg',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                    '--smart-case'
                },
                prompt_prefix = "🔍 ",
                selection_caret = " ",
                path_display = { "truncate" },
            },
            pickers = {
                find_files = {
                    find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                },
            },
        })

        -- telescope-fzf-native builds libfzf.so but does nothing until the extension is
        -- loaded. Without this telescope silently falls back to its slower Lua sorter.
        pcall(require('telescope').load_extension, 'fzf')
    end
}
