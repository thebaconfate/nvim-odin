return {
    "saghen/blink.cmp",
    version = "1.*", -- Use a release tag so the prebuilt Rust fuzzy matcher is downloaded
    -- NOTE: not lazy-loaded on InsertEnter. LSP capabilities are read when a client
    -- starts (BufEnter/FileType), which happens before you ever reach insert mode,
    -- so blink has to be available by then. See lsp-config.lua.
    lazy = false,
    opts = {
        keymap = {
            preset = "default", -- <C-space> open, <C-n>/<C-p> navigate, <C-e> hide
            ["<Tab>"] = { "accept", "fallback" },
            ["<C-y>"] = { "accept", "fallback" },
        },
        appearance = {
            -- Fall back to nvim-cmp's highlight groups, which the vscode colorscheme
            -- already styles.
            use_nvim_cmp_as_default = true,
            -- 'mono' matches Nerd Font Mono glyph widths so the icon column lines up.
            nerd_font_variant = "mono",
        },
        completion = {
            documentation = { auto_show = true },
        },
        -- No custom snippets in this config, so blink's built-in engine is enough.
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        signature = { enabled = true },
        fuzzy = { implementation = "prefer_rust" },
    },
    opts_extend = { "sources.default" },
}
