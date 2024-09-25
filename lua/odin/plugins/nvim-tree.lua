return {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
        'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
    config = function()
        require('nvim-tree').setup({
            disable_netrw = true,
            actions = {
                open_file = {
                    quit_on_open = true,
                },
            },
            filters = {
                dotfiles = false,
                exclude = {
                    ".env", "node_modules",
                },
            },
        })
    end
}
