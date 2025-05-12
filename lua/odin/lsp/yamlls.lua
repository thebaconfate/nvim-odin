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
        },
    },
}
