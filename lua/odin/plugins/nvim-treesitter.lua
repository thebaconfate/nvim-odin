-- nvim-treesitter configuration
return {
	'nvim-treesitter/nvim-treesitter',
	build = ':TSUpdate',  -- Automatically update parsers
	config = function()
		require'nvim-treesitter.configs'.setup {
			ensure_installed = {
				-- Specify the languages you want
				"c",
				"lua",
				"python",
				"javascript",
				"typescript",
                "tsx",
				"scala",
                "css",
                "html",
				"java",
				"astro"
			},
			highlight = {
				enable = true,  -- Enable highlighting
				disable = {},   -- List of languages to disable (if any)
			},
			indent = {
				enable = true,  -- Enable indentation
			},
			-- Optional additional modules (text objects, playground, etc.)
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
					},
				},
			},
		}
	end
}

