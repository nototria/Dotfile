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
	  "lua_ls","clangd","pyright"
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
      vim.keymap.set('n', '<leader>D',vim.lsp.buf.type_definition(),{})
      vim.keymap.set('n', '<leader>rn',vim.lsp.buf.rename(),{})
      vim.keymap.set('n', '<leader>e',vim.lsp.diagnostic.show_line_diagnostics(),{})
      lspconfig.lua_ls.setup({
	capabilities = capabilities
      })
      lspconfig.clangd.setup({
	capabilities = capabilities,
	init_options = {
	  fallbackFlags = {'--std=c++20'}
	  }
      })
      lspconfig.pyright.setup({
	capabilities = capabilities
      })

    end
  }
}
