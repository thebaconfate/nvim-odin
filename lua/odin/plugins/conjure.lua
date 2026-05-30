return {
    "Olical/conjure",
    ft = { "lisp" }, -- Lazy-load only on these filetypes
    init = function()
        -- Explicitly tell Conjure which filetypes it is allowed to target.
        -- This strips out Lua, Python, Rust, etc.
        vim.g["conjure#filetypes"] = { "lisp" }

        -- Optional: If you don't want Conjure overriding 'K' for documentation lookup
        vim.g["conjure#mapping#doc_word"] = false
    end,
}
