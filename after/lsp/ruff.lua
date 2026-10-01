return {
    -- ruff owns linting, import sorting and quick fixes; the Python type checker stays the
    -- source of truth for types and hover. Without this, both answer `K` with different content.
    on_attach = function(client)
        client.server_capabilities.hoverProvider = false
    end,

    -- NOTE: `init_options` is deliberately absent, not empty.
    --
    -- ruff rejects an EMPTY settings object and reports
    --   "Ruff received invalid client settings - falling back to default client settings."
    -- Both `settings = {}` and `settings = vim.empty_dict()` trigger it, so this is not
    -- the usual Lua-empty-table-encodes-as-[] problem. Omitting init_options entirely
    -- is the only clean way to say "no editor settings, use the project's config".
    --
    -- When you DO want editor settings, ruff reads them from `init_options.settings`,
    -- NOT the top-level `settings` key that every other server here uses (lua_ls,
    -- basedpyright, texlab, yamlls, ltex_plus...). Putting them under `settings` fails
    -- silently - no error, no warning, simply ignored. Correct shape:
    --
    --   init_options = {
    --     settings = {
    --       lineLength = 100,
    --       lint = { select = { "E", "F", "I" }, ignore = { "E501" } },
    --       format = { preview = true },
    --       -- How editor settings interact with pyproject.toml / ruff.toml:
    --       --   "editorFirst"     editor wins            (ruff's default)
    --       --   "filesystemFirst" project files win
    --       --   "editorOnly"      project files ignored
    --       configurationPreference = "filesystemFirst",
    --     },
    --   },
}
