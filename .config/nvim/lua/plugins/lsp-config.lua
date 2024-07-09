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
	  "lua_ls","clangd","pyright","r_language_server"
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
      vim.keymap.set('n', '<leader>D',vim.lsp.buf.type_definition,{})
      vim.keymap.set('n', '<leader>rn',vim.lsp.buf.rename,{})
      lspconfig.lua_ls.setup({
	capabilities = capabilities
      })
      lspconfig.clangd.setup({
	capabilities = capabilities,
	init_options = {
	  fallbackFlags = {'--std=c++20'}
	},
	handlers = {
	  ["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
	    result.diagnostics = vim.tbl_filter(function(diagnostic)
	      -- Filter out specific diagnostics
	      return diagnostic.message ~= "Some diagnostic message to ignore"
	    end, result.diagnostics)
	    vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx, config)
	  end
	},
	cmd = { "clangd", "--clang-tidy", "--clang-tidy-checks=-*,clang-analyzer-*"}
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
