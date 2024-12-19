return {
    "windwp/nvim-ts-autotag",
    config = function()
        require("nvim-ts-autotag").setup({})
    end,
    ft = { "html", "javascriptreact", "typescriptreact", "svelte", "vue", "xml", "astro" },
}
