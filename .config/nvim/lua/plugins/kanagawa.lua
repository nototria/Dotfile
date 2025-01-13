return {
  "rebelot/kanagawa.nvim",
  name = "kanagawa",
  priority = 1000,
  config = function()
    vim.cmd.colorscheme "kanagawa-dragon"
    vim.cmd("set number")
    vim.opt.relativenumber = true
    vim.cmd([[
      highlight LineNr guifg=#849ca4 guibg=NONE
      highlight CursorLineNr guifg=#ffffff guibg=NONE
      highlight clear SignColumn
      highlight SignColumn guibg=NONE      
      ]])
  end
}
