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
