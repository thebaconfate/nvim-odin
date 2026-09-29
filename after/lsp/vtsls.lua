return {
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
            -- Surfaces the "move to file" / "extract to file" refactors
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
        },
    },
}
