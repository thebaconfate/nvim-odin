-- nvim-treesitter configuration
return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")

        -- optional (safe default)
        treesitter.setup({
            install_dir = vim.fn.stdpath("data") .. "/site",
        })

        -- install languages
        local ensure_installed = {
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
            "astro",
            "latex",
            "yaml",
            "dockerfile",
            "jsdoc",
            "vimdoc",
            "racket",
            -- "haskell",
            -- "erlang",
            "elixir",
            "heex"
        }

        treesitter.install(ensure_installed)

        -- From https://github.com/nvim-treesitter/nvim-treesitter/issues/8221#issuecomment-3436658280
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if vim.list_contains(treesitter.get_available(), lang) then
                    if not vim.list_contains(treesitter.get_installed(), lang)
                        and not vim.list_contains(ensure_installed, lang)
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
