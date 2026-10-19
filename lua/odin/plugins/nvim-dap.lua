-- EXPERIMENT (branch try-dap): debugging via nvim-dap.
--
-- Configurations come from the nearest .vscode/launch.json above the current file, so
-- the debug configs a team keeps for VS Code work as-is (~/dev/qargo/backend/projects/tms
-- ships ~30: Django runserver, pytest on the current file, the pubsub pullers, attach).
--
-- Keys live under <leader>b ("breakpoint"): <leader>d is delete-to-void in remap.lua, and
-- F-keys need fn on a Mac keyboard.
--
-- No dap-python test_method key: it builds its own config without the launch.json
-- envFile/cwd/PYTHONPATH, so Django tests in tms start without their environment. Use
-- <leader>bc -> "Test current open file against local database" instead.

-- The nearest folder above `path` with a .vscode/launch.json, i.e. the VS Code workspace.
local function workspace_for(path)
    local found = vim.fs.find(".vscode/launch.json", { upward = true, path = vim.fs.dirname(path) })[1]
    return found and vim.fs.dirname(vim.fs.dirname(found))
end

-- Replace VS Code's ${workspaceFolder}/${workspaceRoot} in every string of a config.
-- nvim-dap would expand them to the cwd, which is wrong when nvim was started in the
-- repo root (~/dev/qargo/backend) but launch.json lives in projects/tms.
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
            return vim.tbl_map(function(config)
                config = substitute_workspace(config, root)
                -- VS Code runs from the workspace folder unless told otherwise; the tms
                -- pytest configs rely on it (`-c setup.cfg`, PYTHONPATH=./src).
                config.cwd = config.cwd or root
                return config
            end, configs)
        end

        -- debugpy runs from the project's venv when it has it (with_debugpy above), and from
        -- Mason otherwise, so projects don't need it installed; the program being debugged
        -- runs on the project's venv interpreter (venv_python above).
        local dap_python = require("dap-python")
        dap_python.resolve_python = venv_python
        dap_python.setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")

        -- nvim-dap-python reads `envFile` (debugpy does not), but lets the file override the
        -- config's own `env`. VS Code does the opposite, and several tms configs rely on it:
        -- the pubsub pullers set PUBSUB_PROJECT / PUBSUB_EMULATOR_HOST / ... over the values
        -- in dev-venv.env. Re-apply `env` on top so the config wins, as in VS Code.
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

        -- The panel opens when a session starts and closes when it ends.
        require("dap-view").setup({ auto_toggle = true })

        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
    end,
}
