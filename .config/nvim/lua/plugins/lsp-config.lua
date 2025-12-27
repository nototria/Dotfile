return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        -- mason-lspconfig >= 2.0 uses vim.lsp.enable() under the hood :contentReference[oaicite:0]{index=0}
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "clangd",
                    "pyright",
                    "svlangserver",
                    -- add others here *only* if Mason supports them
                    -- e.g. "r_language_server" if you want Mason to manage it
                },
                -- optional:
                -- automatic_enable = true, -- this is the default
            })
        end,
    },

    {
        "neovim/nvim-lspconfig",
        config = function()
            -- 1. Capabilities (nvim-cmp)
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            -- 2. Global defaults for *all* LSP clients :contentReference[oaicite:1]{index=1}
            vim.lsp.config("*", {
                capabilities = capabilities,
            })
            vim.diagnostic.config({
                -- Only show inline text for Errors
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

            -- 3. Per-server configuration

            -- Lua
            vim.lsp.config("lua_ls", {
                -- add Lua-specific settings here if you want
                -- settings = { ... }
            })

            -- SystemVerilog
            vim.lsp.config("svlangserver", {
            })

            -- C / C++
            vim.lsp.config("clangd", {
                init_options = {
                    clangdFileStatus = true,
                    fallbackFlags = { "--std=c++20" },
                },
                cmd = {
                    "clangd",
                    "--clang-tidy",
                    "--header-insertion=never",
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
            vim.lsp.config("r_language_server", {
                -- extra settings if needed
            })

            -- 4. Enabling servers
            -- If you keep mason-lspconfig's default `automatic_enable` = true,
            -- you do NOT need to call vim.lsp.enable() manually.
            -- Mason will call vim.lsp.enable('<server>') for installed servers. :contentReference[oaicite:2]{index=2}

            -- If you *disable* automatic_enable in mason-lspconfig, then you need:
            -- for _, server in ipairs({
                --   "lua_ls",
                --   "svlangserver",
                --   "clangd",
                --   "pyright",
                --   "r_language_server",
                -- }) do
                --   vim.lsp.enable(server)
                -- end
            end,
        },
    }

