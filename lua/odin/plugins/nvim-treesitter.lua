-- nvim-treesitter configuration
return {
    "nvim-treesitter/nvim-treesitter",
    -- The config below uses the rewritten API (install/get_installed), which only
    -- exists on the main branch. Pin it rather than relying on the default branch.
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")

        -- optional (safe default)
        treesitter.setup({
            install_dir = vim.fn.stdpath("data") .. "/site",
        })

        -- These come pre installed with neovim
        local pre_installed = {
            "c",
            "lua",
            "markdown",
            "markdown_inline",
            "query",
            "vim",
            "vimdoc",
        }

        -- From https://github.com/nvim-treesitter/nvim-treesitter/issues/8221#issuecomment-3436658280
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if vim.list_contains(treesitter.get_available(), lang) then
                    if not vim.list_contains(treesitter.get_installed(), lang)
                        and not vim.list_contains(pre_installed, lang)
                    then
                        treesitter.install(lang):wait()
                    end
                    vim.treesitter.start(args.buf)
                end
            end,
            desc = "Enable nvim-treesitter and install parser if not installed"
        })
    end,
}
