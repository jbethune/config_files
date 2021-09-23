
-- use Lua idioms to define the config
-- (instead of calling the Vim API immediately)

local opts = {
    number=true,
    cursorline=true,
    incsearch=false,
    tw=80,
    colorcolumn="81",
    mouse="a",
    expandtab=true,
    tabstop=4,
    shiftwidth=4,
    omnifunc="v:lua.vim.lsp.omnifunc",
}

local fmap = { -- F-keys
    F3="cnext",
    F4="cfirst",
    F5='lua vim.lsp.diagnostic.show_line_diagnostics()',
    F6="b#",
    F11="clist",
    F12="make"
}

local lsp_keys = {} -- Language server protocol keys
lsp_keys["K"] = "lua vim.lsp.buf.hover()"
lsp_keys["<c-]>"] = "lua vim.lsp.buf.definition()"
lsp_keys["<F2>"] = "lua vim.lsp.buf.rename()"

local cmds = {
    "colorscheme elflord",

    "hi clear SpellBad",
    "hi SpellBad cterm=underline", -- make errors less of an eyesore
}

-- actually setting the options --

-- set the F-keys
for fkey, val in pairs(fmap) do
    vim.api.nvim_set_keymap(
        "n",
        "<" .. fkey .. ">",
        ":" .. val .. "<enter>",
        {noremap=true})
end

-- set the (n)vim options
for key, val in pairs(opts) do
    vim.o[key] = val
end

-- run raw vim commands
for _, cmd in ipairs(cmds) do
    vim.cmd(cmd)
end

-- plugins --

vim.cmd "call plug#begin(stdpath('data') . '/plugged')"
vim.cmd "Plug 'neovim/nvim-lspconfig'"
vim.cmd "call plug#end()"

-- language server protocol --

local nvim_lsp = require "lspconfig"

local custom_lsp_attach = function(client)
    for lsp_key, cmd in pairs(lsp_keys) do
        vim.api.nvim_buf_set_keymap(
            0,
            'n',
            lsp_key,
            "<cmd>" .. cmd .. "<CR>",
            {noremap = true})
    end

    vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

nvim_lsp.rust_analyzer.setup({on_attach=custom_lsp_attach})

-- Taken from https://www.reddit.com/r/neovim/comments/iil3jt/nvimlsp_how_to_display_all_diagnostics_for_entire/
function setup_fill_quickfix()
    local method = "textDocument/publishDiagnostics"
    local default_callback = vim.lsp.handlers[method]
    vim.lsp.handlers[method] = function(err, method, result, client_id)
        default_callback(err, method, result, client_id)
        if result and result.diagnostics then
            local item_list = {}
            for _, v in ipairs(result.diagnostics) do
                local fname = result.uri
                local tab = { filename = fname,
                              lnum = v.range.start.line + 1,
                              col = v.range.start.character + 1,
                              text = v.message; }
                table.insert(item_list, tab)
            end
            local old_items = vim.fn.getqflist()
            for _, old_item in ipairs(old_items) do
                local bufnr = vim.uri_to_bufnr(result.uri)
                if vim.uri_from_bufnr(old_item.bufnr) ~= result.uri then
                    table.insert(item_list, old_item)
                end
            end
            vim.fn.setqflist({}, ' ', { title = 'LSP'; items = item_list; })
        end
    end
end

setup_fill_quickfix()
