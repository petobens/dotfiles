local u = require('utils')

-- Options
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldtext = 'v:lua.vim.treesitter.foldtext()'
vim.opt_local.textwidth = 80
vim.opt_local.linebreak = false
vim.opt_local.spell = true

-- Pandoc
local function convert_pandoc(extension)
    local base_file = vim.fn.expand('%:p:r')
    local output_file = string.format('%s.%s', base_file, extension)
    local pandoc_cmd = 'pandoc -s --toc --number-sections'
    pandoc_cmd = string.format('%s %s.md -o %s', pandoc_cmd, base_file, output_file)
    vim.fn.system(pandoc_cmd)
    if vim.v.shell_error ~= 1 then
        vim.cmd.echo(string.format('"Converted .md file into .%s"', extension))
    end
end

-- Mappings
---- Pandoc
u.keymap('n', '<F7>', function()
    convert_pandoc('pdf')
end, { buffer = true })
u.keymap('n', '<F9>', function()
    convert_pandoc('html')
end, { buffer = true })
u.keymap('n', '<Leader>vp', function()
    vim.fn.jobstart('zathura --fork ' .. vim.fn.expand('%:p:r') .. '.pdf')
end, { buffer = true })
