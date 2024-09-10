local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

require('telescope').setup{
	defaults = {
		vimgrep_arguments = {
			'fd', '--type', 'f', '--hidden', '--follow', '--exclude', '.git'
		},
		prompt_prefix = "🔍 ",
		selection_caret = " ",
		path_display = { "truncate" },
	}
}
