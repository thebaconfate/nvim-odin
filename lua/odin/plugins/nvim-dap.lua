-- EXPERIMENT (branch try-dap): debugging via nvim-dap.
--
-- Configurations come from the nearest .vscode/launch.json above the current file, so
-- the debug configs a team keeps for VS Code work as-is (a dev server, pytest on the
-- current file, background workers, attach).
-- Its compounds are in the same picker and start each of their configs as a session.
--
-- Keys live under <leader>b ("breakpoint"): <leader>d is delete-to-void in remap.lua, and
-- F-keys need fn on a Mac keyboard.
--
-- No dap-python test_method key: it builds its own config without the launch.json
-- envFile/cwd/PYTHONPATH, so tests that need that environment start without it. Use
-- <leader>bc and pick the launch.json config that runs the current test file instead.

-- The nearest folder above `path` with a .vscode/launch.json, i.e. the VS Code workspace.
local function workspace_for(path)
    local found = vim.fs.find(".vscode/launch.json", { upward = true, path = vim.fs.dirname(path) })[1]
    return found and vim.fs.dirname(vim.fs.dirname(found))
end

-- VS Code's `compounds` (several configs started together, e.g. a server and its workers), which
-- nvim-dap's launch.json reader skips, as configs for the `compound` adapter below.
local function compounds(path, configs)
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"), { skip_comments = true })
    if not ok then
        return {}
    end
    local by_name = {}
    for _, config in ipairs(configs) do
        by_name[config.name] = config
    end
    return vim.tbl_map(function(compound)
        local members = {}
        for _, name in ipairs(compound.configurations) do
            table.insert(members, by_name[name])
        end
        return { type = "compound", request = "launch", name = compound.name, members = members }
    end, data.compounds or {})
end

-- Replace VS Code's ${workspaceFolder}/${workspaceRoot} in every string of a config.
-- nvim-dap would expand them to the cwd, which is wrong when nvim was started in a
-- monorepo root but launch.json lives in a project below it.
local function substitute_workspace(value, root)
    if type(value) == "string" then
        return (value:gsub("%${workspaceFolder}", root):gsub("%${workspaceRoot}", root))
    elseif type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = substitute_workspace(v, root)
        end
        return setmetatable(out, getmetatable(value))
    end
    return value
end

-- The project's own interpreter, found the same way conform finds black/isort
-- (lua/odin/plugins/conform.lua): walk up from the file looking for a venv.
local function venv_python()
    local file = vim.api.nvim_buf_get_name(0)
    for dir in vim.fs.parents(file ~= "" and file or vim.fn.getcwd() .. "/x") do
        for _, venv in ipairs({ "venv", ".venv", "env" }) do
            local bin = vim.fs.joinpath(dir, venv, "bin", "python")
            if vim.fn.executable(bin) == 1 then
                return bin
            end
        end
    end
end

-- `python` if its venv has debugpy installed. debugpy's speedups are compiled for one Python
-- version, so Mason's copy (on the global Python) falls back to its slow pure-Python tracer
-- on a venv with another version; the venv's own debugpy always matches it.
local function with_debugpy(python)
    local venv = python and vim.fs.dirname(vim.fs.dirname(python))
    if venv and vim.fn.glob(venv .. "/lib/python*/site-packages/debugpy", true, true)[1] then
        return python
    end
end

-- `call("dap", "step_over")` -> a function that requires the module only when pressed,
-- like pick() in snacks.lua, so the keys table stays one line per mapping.
local function call(module, fn)
    return function()
        require(module)[fn]()
    end
end

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "mfussenegger/nvim-dap-python",
        "igorlfs/nvim-dap-view",
    },
    keys = {
        { "<leader>bb", call("dap", "toggle_breakpoint"), desc = "Debug: toggle breakpoint" },
        {
            "<leader>bB",
            function()
                require("dap").set_breakpoint(vim.fn.input("Condition > "))
            end,
            desc = "Debug: conditional breakpoint",
        },
        { "<leader>bc", call("dap", "continue"), desc = "Debug: start / continue" },
        { "<leader>bn", call("dap", "step_over"), desc = "Debug: next line (step over)" },
        { "<leader>bi", call("dap", "step_into"), desc = "Debug: step into" },
        { "<leader>bo", call("dap", "step_out"), desc = "Debug: step out" },
        { "<leader>br", call("dap", "run_to_cursor"), desc = "Debug: run to cursor" },
        { "<leader>bl", call("dap", "run_last"), desc = "Debug: rerun last config" },
        { "<leader>bq", call("dap", "terminate"), desc = "Debug: stop" },
        {
            "<leader>bQ",
            function()
                require("dap").terminate({ all = true, hierarchy = true })
            end,
            desc = "Debug: stop all sessions",
        },
        { "<leader>bu", call("dap-view", "toggle"), desc = "Debug: toggle panel" },
        { "<leader>bw", call("dap-view", "add_expr"), desc = "Debug: watch word under cursor" },
    },
    config = function()
        local dap = require("dap")

        -- Replaces nvim-dap's own launch.json provider, which only reads <cwd>/.vscode.
        dap.providers.configs["dap.launch.json"] = function(bufnr)
            local file = vim.api.nvim_buf_get_name(bufnr)
            local root = workspace_for(file ~= "" and file or vim.fn.getcwd() .. "/x")
            if not root then
                return {}
            end
            local ok, configs = pcall(require("dap.ext.vscode").getconfigs, root .. "/.vscode/launch.json")
            if not ok then
                vim.notify("Can't read " .. root .. "/.vscode/launch.json:\n" .. configs, vim.log.levels.WARN)
                return {}
            end
            configs = vim.tbl_map(function(config)
                config = substitute_workspace(config, root)
                -- VS Code runs from the workspace folder unless told otherwise; configs with
                -- relative paths rely on it (`-c setup.cfg`, PYTHONPATH=./src).
                config.cwd = config.cwd or root
                return config
            end, configs)
            return vim.list_extend(compounds(root .. "/.vscode/launch.json", configs), configs)
        end

        -- debugpy runs from the project's venv when it has it (with_debugpy above), and from
        -- Mason otherwise, so projects don't need it installed; the program being debugged
        -- runs on the project's venv interpreter (venv_python above).
        local dap_python = require("dap-python")
        dap_python.resolve_python = venv_python
        dap_python.setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")

        -- nvim-dap-python reads `envFile` (debugpy does not), but lets the file override the
        -- config's own `env`. VS Code does the opposite, and configs rely on it to override
        -- single values from a shared env file. Re-apply `env` on top so the config wins, as
        -- in VS Code.
        local python_adapter = dap.adapters.python
        dap.adapters.python = function(cb, config)
            python_adapter(function(adapter)
                -- Only a launched adapter has a command; attach connects to a running server
                if adapter.type == "executable" then
                    local python = type(config.python) == "string" and config.python or venv_python()
                    adapter.command = with_debugpy(python) or adapter.command
                end
                local enrich = adapter.enrich_config
                if enrich then
                    adapter.enrich_config = function(cfg, on_config)
                        local own_env = vim.deepcopy(cfg.env or {})
                        enrich(cfg, function(enriched)
                            enriched.env = vim.tbl_extend("force", enriched.env or vim.empty_dict(), own_env)
                            on_config(enriched)
                        end)
                    end
                end
                cb(adapter)
            end, config)
        end
        dap.adapters.debugpy = dap.adapters.python

        -- Starts each member as its own session instead of starting a debugger: `cb` is never
        -- called, so the compound itself gets no session.
        dap.adapters.compound = function(_, config)
            for _, member in ipairs(config.members) do
                dap.run(member)
            end
        end

        -- The panel opens when a session starts and closes when it ends.
        require("dap-view").setup({
            auto_toggle = true,
            -- The defaults plus Sessions (K, only in the panel): compounds run several at once.
            winbar = {
                sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "sessions" },
            },
        })

        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
    end,
}
