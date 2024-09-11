return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional, for icons
  config = function()
    require('lualine').setup({
  options = {
    theme = 'codedark' -- Automatically syncs with the `onedarkpro` color scheme
  }
        })
  end
}
