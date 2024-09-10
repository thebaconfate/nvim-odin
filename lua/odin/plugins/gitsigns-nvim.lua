return {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }, -- Required dependency
    config = function()
        require('gitsigns').setup()
    end
}
