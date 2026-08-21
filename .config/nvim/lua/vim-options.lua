-- Basic editor options
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.numberwidth = 4
vim.opt.signcolumn = "yes"

-- The dashboard hides its window-local sign column. Restore it when that
-- window is reused for a normal file buffer.
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        if vim.bo.buftype == "" then
            vim.wo.signcolumn = "yes"
        end
    end,
    desc = "Show diagnostic signs in file buffers",
})

vim.g.mapleader = " "

-- Diagnostics toggle
local function ToggleDiagnostics()
    local enabled = vim.diagnostic.is_enabled()

    vim.diagnostic.enable(not enabled)

    if enabled then
        print("diagnostic disabled")
    else
        print("diagnostic enabled")
    end
end

vim.keymap.set("n", "<leader>dn", ToggleDiagnostics, {
    noremap = true,
    silent = true,
    desc = "Toggle diagnostics",
})

-- Show full diagnostics for current line
vim.keymap.set("n", "<leader>e", function()
    vim.diagnostic.open_float(nil, {
        focus = false,
        scope = "line",
    })
end, {
    noremap = true,
    silent = true,
    desc = "Line diagnostics",
})

-- Neotree toggle
vim.keymap.set("n", "<leader>tt", "<cmd>Neotree toggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Toggle Neotree",
})

-- tmux-vim navigator hotkeys
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", {
    noremap = true,
    silent = true,
    desc = "Navigate left",
})

vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", {
    noremap = true,
    silent = true,
    desc = "Navigate down",
})

vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", {
    noremap = true,
    silent = true,
    desc = "Navigate up",
})

vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", {
    noremap = true,
    silent = true,
    desc = "Navigate right",
})

-- LSP hotkeys
vim.keymap.set("n", "K", vim.lsp.buf.hover, {
    noremap = true,
    silent = true,
    desc = "LSP hover",
})

vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {
    noremap = true,
    silent = true,
    desc = "LSP code action",
})

vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {
    noremap = true,
    silent = true,
    desc = "LSP definition",
})

vim.keymap.set("n", "<leader>gD", vim.lsp.buf.declaration, {
    noremap = true,
    silent = true,
    desc = "LSP declaration",
})

vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, {
    noremap = true,
    silent = true,
    desc = "LSP type definition",
})

vim.keymap.set("n", "<leader>sh", vim.lsp.buf.signature_help, {
    noremap = true,
    silent = true,
    desc = "LSP signature help",
})

vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {
    noremap = true,
    silent = true,
    desc = "LSP references",
})

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {
    noremap = true,
    silent = true,
    desc = "LSP rename",
})

-- clang-format current buffer
vim.keymap.set("n", "<leader>cf", function()
    local buf = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = buf, name = "clangd" })

    if #clients == 0 then
        vim.notify("clangd is not attached to this buffer", vim.log.levels.ERROR)
        return
    end

    vim.lsp.buf.format({
        bufnr = buf,
        name = "clangd",
        async = false,
    })
end, {
    noremap = true,
    silent = true,
    desc = "clang-format buffer",
})
