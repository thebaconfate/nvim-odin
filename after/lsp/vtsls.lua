local ts = require("odin.typescript")

return {
    -- Step aside for tsc in projects on TypeScript 7+ (see after/lsp/tsc.lua). vtsls only
    -- bundles TS 5.x and TS 7 has no tsserver for it to use, so there it would type-check
    -- with a different compiler than the project's.
    root_dir = function(bufnr, on_dir)
        local root = ts.project_root(bufnr)
        if ts.uses_native(root) then
            return
        end
        -- Same cwd fallback as the bundled config, for loose files outside any project.
        if root or not vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            on_dir(root or vim.fn.getcwd())
        end
    end,

    settings = {
        -- Inlay hints are the main reason to run vtsls over ts_ls; they are off by
        -- default. `typescript` and `javascript` take the same shape.
        typescript = {
            inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
            updateImportsOnFileMove = { enabled = "always" },
        },
        javascript = {
            inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
            updateImportsOnFileMove = { enabled = "always" },
        },
        vtsls = {
            -- Fuzzy-filter completions in the server, so large lists are trimmed
            -- before they are sent to the client
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
        },
    },
}
