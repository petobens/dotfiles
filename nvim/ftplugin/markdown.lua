local u = require('utils')

-- Options
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldtext = 'v:lua.vim.treesitter.foldtext()'
vim.opt_local.textwidth = 80
vim.opt_local.linebreak = false
vim.opt_local.spell = true
vim.opt_local.formatexpr = ''
vim.opt_local.conceallevel = 2

-- Autocommand options
vim.api.nvim_create_autocmd(
    ---- Refresh folds
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        group = vim.api.nvim_create_augroup('md_folds', { clear = true }),
        pattern = { '*.md' },
        callback = function()
            vim.cmd('normal! zx')
        end,
    }
)

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

local function toggle_checklist()
    -- https://github.com/opdavies/toggle-checkbox.nvim/blob/main/lua/toggle-checkbox.lua
    local unchecked = '%[ %]'
    local checked = '%[x%]'
    local bufnr = vim.api.nvim_buf_get_number(0)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local start_line = cursor[1] - 1
    local current_line = vim.api.nvim_buf_get_lines(
        bufnr,
        start_line,
        start_line + 1,
        false
    )[1] or ''

    local new_line
    if string.find(current_line, unchecked) then
        new_line = current_line:gsub(unchecked, checked)
    else
        new_line = current_line:gsub(checked, unchecked)
    end
    vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { new_line })
    vim.api.nvim_win_set_cursor(0, cursor)
end

-- Mappings
u.keymap('n', '<F7>', function()
    convert_pandoc('pdf')
end, { buffer = true })
u.keymap('n', '<F9>', function()
    convert_pandoc('html')
end, { buffer = true })
u.keymap('n', '<Leader>vp', function()
    vim.fn.jobstart('zathura --fork ' .. vim.fn.expand('%:p:r') .. '.pdf')
end, { buffer = true })
u.keymap('n', '<Leader>ct', toggle_checklist, { buffer = true })
