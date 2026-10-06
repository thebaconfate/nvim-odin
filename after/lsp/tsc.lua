local ts = require("odin.typescript")

return {
    -- NOTE: cmd and root_dir are replaced as a pair. nvim-lspconfig's bundled root_dir is
    -- what records which binary its cmd runs, so overriding root_dir alone would make cmd
    -- fall back to a global `tsc` - which is not installed. This always runs the project's
    -- own compiler, so the editor type-checks with exactly the TypeScript CI uses.
    cmd = function(dispatchers, config)
        local bin = vim.fs.joinpath(config.root_dir, "node_modules", ".bin", "tsc")
        return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
    end,
    -- Attach only to projects on TS 7+, and silently: the bundled config warns
    -- "no binary supporting --lsp found" in every other JS/TS project.
    root_dir = function(bufnr, on_dir)
        local root = ts.project_root(bufnr)
        if ts.uses_native(root) then
            on_dir(root)
        end
    end,
    settings = {
        -- Same inlay hints as after/lsp/vtsls.lua: the bundled default also shows
        -- variable types, which is noisy on every `const`.
        ["js/ts"] = {
            inlayHints = {
                variableTypes = { enabled = false },
            },
        },
    },
}
