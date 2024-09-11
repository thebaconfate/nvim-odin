return {
  'akinsho/toggleterm.nvim',
  version = "*", -- You can specify a specific version or "*" for the latest
  config = function()
    require('toggleterm').setup({
            -- Customize settings here
    shell = (vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1) and 'pwsh' or vim.o.shell,
      size = 10,
      open_mapping = [[<C-i>]], -- Keybinding to toggle the terminal
      direction = 'horizontal', -- Other options: 'horizontal', 'vertical', 'tab'
      shade_terminals = true,
      shading_factor = 2,
      persist_size = true,
      close_on_exit = true,
    })
  end
}
