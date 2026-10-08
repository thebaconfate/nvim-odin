return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional, for icons
    config = function()
        require('lualine').setup({
            options = {
                theme = 'vscode' -- Ships with Mofiqul/vscode.nvim, so mode colours match the colorscheme
            }
        })
    end
}
