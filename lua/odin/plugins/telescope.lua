local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

local function get_shell()
    if vim.fn.has("win32") == 0 then
        -- Native linux, return the shell
        vim.notify("Native linux, using native bash")
        return (vim.env.SHELL or "/bin/bash") .. " -c"
    end
    local git_bash = "C:\\Program Files\\Git\\bin\\bash.exe" -- Use Git Bash
    local wingw64 = "C:\\msys64\\mingw64.exe"
    if file_exists(wingw64) then
        return wingw64
    elseif file_exists(git_bash) then
        vim.notify("No msys64 found, defaulting to git bash as shell. Please install msys64 for future use")
        return git_bash
    else
        vim.notify(
            "No Bash found! Some features may not work.",
            vim.log.levels.WARN
        )
        return nil
    end
end

return {
    'nvim-telescope/telescope.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',                                                       -- Required dependency
        'nvim-treesitter/nvim-treesitter',                                             -- Optional for better previewing
        'nvim-web-devicons',                                                           -- Optional for file icons
        'sharkdp/fd',                                                                  -- Optional for faster file searching
        'neovim/nvim-lspconfig',                                                       -- Optional for LSP integration
        { 'nvim-telescope/telescope-fzf-native.nvim', build = get_shell() .. ' make' } -- NOTE: Won't build on windows unless you use wingw64
    },
    config = function()
        require('telescope').setup({
        })
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
    end
}
