local parsers = { "c", "cpp", "lua", "markdown", "markdown_inline", "python", "vim", "vimdoc" }
local filetypes = { "c", "cpp", "lua", "markdown", "python", "vim", "vimdoc" }

return {
  {
    "neovim-treesitter/nvim-treesitter",
    dependencies = { "neovim-treesitter/treesitter-parser-registry" },
    lazy = false,
    build = function()
      require("nvim-treesitter").install(parsers):wait(300000)
    end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function()
          vim.treesitter.start()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
