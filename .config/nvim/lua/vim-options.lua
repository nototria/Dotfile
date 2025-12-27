vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set expandtab")
vim.cmd("set number")
vim.g.mapleader = " "
vim.o.numberwidth = 4

--auto-complete brace
local function auto_complete_braces()
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0)) local current_line = vim.api.nvim_get_current_line()
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

-- movement between window
vim.keymap.set('n','<c-k>',':wincmd k<CR>')
vim.keymap.set('n','<c-j>',':wincmd j<CR>')
vim.keymap.set('n','<c-h>',':wincmd h<CR>')
vim.keymap.set('n','<c-l>',':wincmd l<CR>')

-- Function to toggle diagnostics
local diagnostics_enabled = true

local function ToggleDiagnostics()
  diagnostics_enabled = not diagnostics_enabled
  if diagnostics_enabled then
    vim.diagnostic.enable()
    print("diagnostic enable")
  else
    vim.diagnostic.disable()
    print("diagnostic disable")
  end
end

-- treesitter hotkey
vim.keymap.set('n', '<leader>tt', ':Neotree toggle<CR>', {})

-- tmux-vim navigator hotkey
vim.keymap.set('n','C-h', ':TmuxNavigateLeft<CR>')
vim.keymap.set('n','C-j', ':TmuxNavigateDown<CR>')
vim.keymap.set('n','C-k', ':TmuxNavigateUp<CR>')
vim.keymap.set('n','C-l', ':TmuxNavigateRight<CR>')

-- lsp hotkey
vim.keymap.set('n','K',vim.lsp.buf.hover,{})
vim.keymap.set({'n'},'<leader>ca',vim.lsp.buf.code_action,{})
vim.keymap.set('n', '<leader>gd',vim.lsp.buf.definition,{})
vim.keymap.set('n','<leader>gD',vim.lsp.buf.declaration,{})
vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition,{})
vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help,{})
vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references,{})
vim.keymap.set('n', '<leader>rn',vim.lsp.buf.rename,{})

-- Keymap to toggle diagnostics
vim.keymap.set('n', '<leader>dn', ToggleDiagnostics, { noremap = true, silent = true })

-- show full diagnostics
vim.keymap.set("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { focus = false, scope = "line" })
end, { desc = "Line diagnostics" })
