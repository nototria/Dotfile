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
	  "lua_ls","clangd","pyright","svlangserver"
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
      vim.keymap.set('n','K',vim.lsp.buf.hover,{})
      vim.keymap.set({'n'},'<leader>ca',vim.lsp.buf.code_action,{})
      vim.keymap.set('n', '<leader>gd',vim.lsp.buf.definition,{})
      vim.keymap.set('n','<leader>gD',vim.lsp.buf.declaration,{})
      vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition,{})
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help,{})
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references,{})
      vim.keymap.set('n', '<leader>rn',vim.lsp.buf.rename,{})
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
	settings = {
	  r = {
	    lsp = {
	      diagnostics = false
	      -- diagnostics = {
	      --   disabled = { "lintr::infix_spaces_linter", "lintr::object_length_linter" },
	      -- }
	    }
	  }
	}
      })
    end
  }
}
