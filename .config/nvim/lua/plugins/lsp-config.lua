return {
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            vim.lsp.log.set_level(vim.log.levels.OFF)

            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            -- Global default config for all LSP clients
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            vim.diagnostic.config({
                virtual_text = {
                    severity = vim.diagnostic.severity.ERROR,
                },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                float = {
                    border = "rounded",
                    source = "always",
                },
            })

            -- Lua
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                    },
                },
            })

            -- SystemVerilog
            vim.lsp.config("svlangserver", {})

            -- C / C++
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--clang-tidy",
                    "--header-insertion=never",
                },
                init_options = {
                    clangdFileStatus = true,
                    fallbackFlags = { "--std=c++20" },
                },
            })

            -- Python
            vim.lsp.config("pyright", {
                settings = {
                    python = {
                        analysis = {
                            diagnosticMode = "openFilesOnly",
                            typeCheckingMode = "off",
                            useLibraryCodeForTypes = true,
                            diagnosticSeverityOverrides = {
                                reportGeneralTypeIssues = "none",
                                reportOptionalSubscript = "none",
                            },
                        },
                    },
                },
            })

            -- R
            vim.lsp.config("r_language_server", {})

            -- mason-lspconfig v2 automatically enables installed servers by default
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "clangd",
                    "pyright",
                    "svlangserver",
                },
                automatic_enable = true,
            })

            -- Enable R manually if it is installed outside Mason.
            -- If Mason supports it in your setup, you can instead add it to ensure_installed.
            vim.lsp.enable("r_language_server")
        end,
    },
}
