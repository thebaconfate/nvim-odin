return {
    settings = {
        yaml = {
            schemas = {
                -- Add GitHub Actions schema for workflows
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                -- Kubernetes files will only be recognized if they're in a k8s directory. Otherwise it clashes with other yaml schemas
                kubernetes = "/k8s/*.yaml",
            },

            validate = true,   -- Enable YAML validation
            completion = true, -- Enable autocompletion
            hover = true,      -- Enable hover documentation
            -- NOTE: conform has no YAML formatter, so format-on-save fell back to this
            -- server's prettier-based formatter and rewrote whole files ('x' -> "x",
            -- `[ a ]` -> `[a]`, list re-indents). That would touch ~40% of the YAML in
            -- ~/dev/qargo/backend. Off, so a one-line edit stays a one-line diff.
            format = { enable = false },
        },
    },
}
