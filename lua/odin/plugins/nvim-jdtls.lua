return {
    -- jdtls through nvim-lspconfig shares a single workspace directory across every
    -- project, which is the usual cause of stale indexes and "project not found".
    -- nvim-jdtls gives each project its own workspace. Same shape as nvim-metals.
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
        local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

        local group = vim.api.nvim_create_augroup("nvim-jdtls", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            group = group,
            callback = function(args)
                if vim.fn.executable(jdtls_bin) == 0 then
                    vim.notify("jdtls not installed - run :MasonToolsInstall", vim.log.levels.WARN)
                    return
                end

                local root = vim.fs.root(args.buf, {
                    "settings.gradle",
                    "settings.gradle.kts",
                    "build.gradle",
                    "build.gradle.kts",
                    "pom.xml",
                    "mvnw",
                    "gradlew",
                    ".git",
                })
                if not root then
                    return
                end

                -- One workspace per project root, keyed by its path so two projects
                -- with the same directory name do not collide.
                local key = vim.fn.fnamemodify(root, ":p:h:t") .. "-" .. vim.fn.sha256(root):sub(1, 8)
                local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. key

                local ok, blink = pcall(require, "blink.cmp")

                require("jdtls").start_or_attach({
                    cmd = { jdtls_bin, "-data", workspace },
                    root_dir = root,
                    capabilities = ok and blink.get_lsp_capabilities(nil, true)
                        or vim.lsp.protocol.make_client_capabilities(),
                    settings = {
                        java = {
                            signatureHelp = { enabled = true },
                            contentProvider = { preferred = "fernflower" }, -- decompile class files
                            inlayHints = { parameterNames = { enabled = "all" } },
                        },
                    },
                    init_options = { bundles = {} },
                })
            end,
            desc = "Start jdtls with a per-project workspace",
        })
    end,
}
