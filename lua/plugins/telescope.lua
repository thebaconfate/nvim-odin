return {
	'nvim-telescope/telescope.nvim', tag = '0.1.8',
	-- or                              , branch = '0.1.x',
	dependencies = {
		'nvim-lua/plenary.nvim',             -- Required dependency
		'nvim-treesitter/nvim-treesitter',   -- Optional for better previewing
		'nvim-web-devicons',                 -- Optional for file icons
		'sharkdp/fd',                        -- Optional for faster file searching
		'neovim/nvim-lspconfig',             -- Optional for LSP integration }
	}
}
