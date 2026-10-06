local function file_contains(path, needle)
    local f = io.open(path, "r")
    if not f then
        return false
    end
    local content = f:read("*a")
    f:close()
    return content:find(needle, 1, true) ~= nil
end

-- The linter a project is configured for, decided by the nearest config walking up from
-- `path`: "ruff", "flake8", or nil when neither is configured.
local function project_linter(path)
    for dir in vim.fs.parents(path) do
        local function at(name)
            return vim.fs.joinpath(dir, name)
        end
        if
            vim.uv.fs_stat(at("ruff.toml"))
            or vim.uv.fs_stat(at(".ruff.toml"))
            or file_contains(at("pyproject.toml"), "[tool.ruff")
        then
            return "ruff"
        end
        if
            vim.uv.fs_stat(at(".flake8"))
            or file_contains(at("setup.cfg"), "[flake8]")
            or file_contains(at("tox.ini"), "[flake8]")
        then
            return "flake8"
        end
    end
end

return {
    -- Stay out of projects that lint with flake8 and have no ruff config of their own
    -- (e.g. ~/dev/qargo/backend). There ruff falls back to its defaults - several
    -- hundred rules - and flags thousands of things CI never checks, such as the F401
    -- re-exports flake8's per-file-ignores allow in __init__.py. Projects with a ruff
    -- config, or with no linter config at all, still get ruff.
    root_dir = function(bufnr, on_dir)
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= "" and project_linter(name) == "flake8" then
            return
        end
        on_dir(vim.fs.root(bufnr, { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" }))
    end,

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
