vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.g.mapleader = " "
vim.o.numberwidth = 2

--auto-complete brace
local function auto_complete_braces()
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  local current_line = vim.api.nvim_get_current_line()
  local current_indent = string.match(current_line, "^%s*")
  local shiftwidth = vim.api.nvim_get_option("shiftwidth")
  local tab_spaces = string.rep(" ", shiftwidth)
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, {
    "{",
    current_indent .. tab_spaces,
    current_indent .. "}"
  })
  vim.api.nvim_win_set_cursor(0, {row + 1, #current_indent + shiftwidth + 1})
end
vim.keymap.set('i', '{', auto_complete_braces, { noremap = true, silent = true })
vim.cmd("inoremap ( ()<Esc>ha")
vim.cmd("inoremap [ []<Esc>ha")
vim.cmd("inoremap ' ''<Esc>ha")
vim.cmd([[inoremap " ""<Esc>i]])

--movement between window
vim.keymap.set('n','<c-k>',':wincmd k<CR>')
vim.keymap.set('n','<c-j>',':wincmd j<CR>')
vim.keymap.set('n','<c-h>',':wincmd h<CR>')
vim.keymap.set('n','<c-l>',':wincmd l<CR>')
