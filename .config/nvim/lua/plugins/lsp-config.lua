return{
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config =function()
      require("mason-lspconfig").setup({
	ensure_installed = {
	  "lua_ls","clangd","pyright",
	}
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      lspconfig.lua_ls.setup({
	capabilities = capabilities
      })
      lspconfig.svlangserver.setup({
	capabilities = capabilities
      })

      lspconfig.clangd.setup({
	capabilities = capabilities,
	init_options = {
	  fallbackFlags = {'--std=c++20'}
	}
      })
      lspconfig.pyright.setup({
	capabilities = capabilities,
	settings = {
	  python = {
	    analysis = {
	      diagnosticMode = "openFilesOnly",
	      typeCheckingMode = "off",
	      useLibraryCodeForTypes = true,
	      diagnosticSeverityOverrides = {
		reportGeneralTypeIssues = "none",
		reportOptionalSubscript = "none",
	      }
	    }
	  }
	}
      })
      lspconfig.r_language_server.setup({
	capabilities = capabilities,
      })
    end
  }
}
