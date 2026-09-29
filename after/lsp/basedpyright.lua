return {
    settings = {
        -- NOTE: basedpyright reads its settings from `basedpyright.*`, not `python.*`
        -- the way pyright does. Keeping the old key here would silently do nothing.
        basedpyright = {
            analysis = {
                -- basedpyright enables every rule by default ("maximum discoverability"),
                -- which is far louder than pyright's default on an existing codebase.
                -- "standard" matches the behaviour pyright had here.
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                -- NOTE: useLibraryCodeForTypes is deliberately unset. It defaults to true,
                -- and setting it explicitly overrides per-project pyproject.toml config.
            },
        },
    },
}
