-- TODO:
-- Add incremntal selection

-- Setup
require('nvim-treesitter').install({
    'bash',
    'comment',
    'diff',
    'dockerfile',
    'html',
    'java',
    'json',
    'latex',
    'lua',
    'make',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'regex',
    'rst',
    'sql',
    'toml',
    'vim',
    'vimdoc',
    'yaml',
})

-- Ft/Langugage register
vim.treesitter.language.register('markdown', 'blink-cmp-documentation')
vim.treesitter.language.register('markdown', 'codecompanion')
vim.treesitter.language.register('yaml', 'ghaction')

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Start Tree-sitter except for LaTeX files',
    callback = function(args)
        local filetype = args.match
        if filetype == 'tex' then
            return
        end
        local lang = vim.treesitter.language.get_lang(filetype)
        if vim.treesitter.language.add(lang) then
            vim.treesitter.start()
        end
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>it', function()
    vim.treesitter.inspect_tree({
        command = 'vnew | wincmd H | vertical resize 60',
        title = function()
            return 'InspectTree'
        end,
    })
    vim.keymap.set(
        'n',
        'q',
        require('utils').quit_return,
        { desc = 'Quit InspectTree window' }
    )
end, { desc = 'Open Tree-sitter InspectTree in vertical split' })

-- Text Objects
require('nvim-treesitter-textobjects').setup({
    move = {
        set_jumps = true,
    },
})

-- Mappings
local ts_move = require('nvim-treesitter-textobjects.move')
local ts_select = require('nvim-treesitter-textobjects.select')
local ts_swap = require('nvim-treesitter-textobjects.swap')

-- Select
vim.keymap.set({ 'x', 'o' }, 'af', function()
    ts_select.select_textobject('@function.outer', 'textobjects')
end, { desc = 'Select around function (outer)' })

vim.keymap.set({ 'x', 'o' }, 'if', function()
    ts_select.select_textobject('@function.inner', 'textobjects')
end, { desc = 'Select inside function (inner)' })

vim.keymap.set({ 'x', 'o' }, 'ac', function()
    ts_select.select_textobject('@class.outer', 'textobjects')
end, { desc = 'Select around class (outer)' })

vim.keymap.set({ 'x', 'o' }, 'ic', function()
    ts_select.select_textobject('@class.inner', 'textobjects')
end, { desc = 'Select inside class (inner)' })

vim.keymap.set({ 'x', 'o' }, 'ai', function()
    ts_select.select_textobject('@conditional.outer', 'textobjects')
end, { desc = 'Select around conditional (outer)' })

vim.keymap.set({ 'x', 'o' }, 'as', function()
    ts_select.select_textobject('@local.scope', 'locals')
end, { desc = 'Select around local scope' })

vim.keymap.set('n', '<Leader>if', function()
    ts_select.select_textobject('@function.inner')
end, { desc = 'Select inside function (works in injections)' })

vim.keymap.set('n', '<Leader>af', function()
    ts_select.select_textobject('@function.outer')
end, { desc = 'Select around function (works in injections)' })

-- Move
vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
    ts_move.goto_next_start('@class.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to next class start' })

vim.keymap.set({ 'n', 'x', 'o' }, ']C', function()
    ts_move.goto_next_end('@class.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to next class end' })

vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
    ts_move.goto_previous_start('@class.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to previous class start' })

vim.keymap.set({ 'n', 'x', 'o' }, '[C', function()
    ts_move.goto_previous_end('@class.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to previous class end' })

vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
    ts_move.goto_next_start('@function.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to next function start' })

vim.keymap.set({ 'n', 'x', 'o' }, ']F', function()
    ts_move.goto_next_end('@function.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to next function end' })

vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
    ts_move.goto_previous_start('@function.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to previous function start' })

vim.keymap.set({ 'n', 'x', 'o' }, '[F', function()
    ts_move.goto_previous_end('@function.outer', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to previous function end' })

vim.keymap.set({ 'n', 'x', 'o' }, ']p', function()
    ts_move.goto_next_start('@parameter.inner', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to next parameter' })

vim.keymap.set({ 'n', 'x', 'o' }, '[p', function()
    ts_move.goto_previous_start('@parameter.inner', 'textobjects')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Go to previous parameter' })

-- Swap
vim.keymap.set('n', '<A-l>', function()
    ts_swap.swap_next('@parameter.inner')
end, { desc = 'Swap with next parameter' })

vim.keymap.set('n', '<A-h>', function()
    ts_swap.swap_previous('@parameter.inner')
end, { desc = 'Swap with previous parameter' })
