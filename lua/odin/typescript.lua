-- Shared by after/lsp/tsc.lua and after/lsp/vtsls.lua, so exactly one TypeScript server
-- attaches per project: tsc (TypeScript 7's native `tsc --lsp`) where the project ships
-- TS 7+, vtsls (tsserver-based, bundles its own TS 5.x) everywhere else.
local M = {}

-- Same root detection as nvim-lspconfig's vtsls/tsc configs: the nearest package-manager
-- lockfile, else .git. Returns nil for Deno projects, which neither server should touch.
function M.project_root(bufnr)
    local lockfiles = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
    local root = vim.fs.root(bufnr, { lockfiles, { ".git" } })
    local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
    if deno_root and (not root or #deno_root >= #root) then
        return nil
    end
    return root
end

-- Major version of the TypeScript installed in the project, or nil if there is none.
-- Read from package.json rather than by running `tsc --version`, so it costs a file read
-- instead of a process spawn on every buffer.
function M.major(root)
    local f = io.open(vim.fs.joinpath(root, "node_modules", "typescript", "package.json"), "r")
    if not f then
        return nil
    end
    local ok, pkg = pcall(vim.json.decode, f:read("*a"))
    f:close()
    local version = ok and pkg.version and vim.version.parse(pkg.version)
    return version and version.major or nil
end

function M.uses_native(root)
    return root ~= nil and (M.major(root) or 0) >= 7
end

return M
