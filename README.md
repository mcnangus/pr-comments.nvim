# pr-comments.nvim
Use [lsp_lines](https://git.sr.ht/~whynothugo/lsp_lines.nvim) to load pr comments into neovim using vim quickfix list and diagnostics

## Requirements

Requires [lsp_lines](https://git.sr.ht/~whynothugo/lsp_lines.nvim), follow installation steps in the link.

## Installation

### Lazy

```lua
{
    'mcnangus/pr-comments.nvim',
    config = function()
        -- Call the function to load the quickfix list as diagnostics
        local function load_quickfix_as_diagnostics()
            vim.diagnostic.reset(1)
            vim.fn.setqflist {}
            local buffer = require 'pr-comments'
            if buffer ~= nil then
                for i in buffer:gmatch '([^\n]+)' do
                    vim.cmd('caddexpr "' .. i .. '"')
                end
                local qflist = vim.fn.getqflist()
                local diagnostics = vim.diagnostic.fromqflist(qflist)

                for _, diagnostic in ipairs(diagnostics) do
                    diagnostic.severity = vim.diagnostic.severity.INFO
                end

                vim.diagnostic.set(1, 0, diagnostics)
            end
        end

        vim.keymap.set('', '<Leader>k', load_quickfix_as_diagnostics, { desc = 'Toggle gh pr comments' })
    end,
}
```

