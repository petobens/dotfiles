-- Options
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldtext = ''
vim.opt_local.textwidth = 80
vim.opt_local.linebreak = false
vim.opt_local.spell = true
vim.opt_local.formatexpr = ''
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = 'nc'

-- Autocommand options
vim.api.nvim_create_autocmd(
    ---- Refresh folds
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        group = vim.api.nvim_create_augroup('md_folds', { clear = true }),
        pattern = { '*.md' },
        callback = function()
            -- If a choice node is active then `zx` is inserted
            if not require('luasnip').choice_active() then
                vim.cmd('normal! zx')
            end
        end,
    }
)

-- Functions
---- Lists
local function continue_list()
    local line = vim.fn.substitute(vim.fn.getline(vim.fn.line('.')), '^\\s*', '', '')
    local marker = vim.fn.matchstr(line, [[^\([*-]\s\[\s\]\|[*-]\|>\|\d\+\.\)\s]])
    if not marker or line == '' then
        return '<CR>'
    end
    if line == marker then
        return '<C-U>'
    end
    if marker:match('%d+') then
        marker = marker + 1 .. '. '
    end
    return '<CR>' .. marker
end

local function indent_list(dedent)
    local line = vim.fn.substitute(vim.fn.getline(vim.fn.line('.')), '^\\s*', '', '')
    local marker = vim.fn.matchstr(line, [[^\([*-]\s\[\s\]\|[*-]\|>\|\d\+\.\)\s]])
    if line == marker then
        if dedent then
            return '<C-d>'
        else
            return '<C-t>'
        end
    else
        return '<Tab>'
    end
end

local function toggle_checklist()
    -- https://github.com/opdavies/toggle-checkbox.nvim/blob/main/lua/toggle-checkbox.lua
    local unchecked = '%[ %]'
    local doing = '%[_%]'
    local done = '%[x%]'
    local wontdo = '%[~%]'

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
        new_line = current_line:gsub(unchecked, doing)
    elseif string.find(current_line, doing) then
        new_line = current_line:gsub(doing, done)
    elseif string.find(current_line, done) then
        new_line = current_line:gsub(done, wontdo)
    else
        new_line = current_line:gsub(wontdo, unchecked)
    end
    vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { new_line })
    vim.api.nvim_win_set_cursor(0, cursor)
end

---- Pandoc
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

---- Sphinx
local function build_sphinx_docs()
    local on_exit = function(obj)
        if obj.code == 0 then
            vim.print('HTML docs built successfully')
        else
            vim.print(obj.stderr)
            vim.print('HTML docs build failed!')
        end
    end

    local project_root = vim.fn.fnamemodify(
        vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';'),
        ':p:h'
    )
    vim.print('Building HTML docs...')
    vim.system(
        { 'poetry', 'run', 'make', 'html' },
        { cwd = project_root .. '/docs', text = true },
        on_exit
    )
end

local function view_sphinx_docs()
    local file_dir = vim.fn.expand('%:p:r')
    local html_file = file_dir:match('docs/source/(.*)') .. '.html'
    local docs_dir = vim.fn.fnamemodify(
        vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';'),
        ':p:h'
    ) .. '/docs/build/html/'
    vim.ui.open(docs_dir .. html_file)
end

-- Mappings
---- Compiling
vim.keymap.set('n', '<F7>', function()
    convert_pandoc('pdf')
end, { buffer = true })
vim.keymap.set('n', '<F9>', function()
    convert_pandoc('html')
end, { buffer = true })
vim.keymap.set('n', '<Leader>vp', function()
    vim.system({ 'zathura', '--fork', vim.fn.expand('%:p:r') .. '.pdf' })
end, { buffer = true })
---- Lists
vim.keymap.set('i', '<CR>', continue_list, { expr = true, buffer = true })
vim.keymap.set('i', '<Tab>', indent_list, { expr = true, buffer = true })
vim.keymap.set('i', '<S-Tab>', function()
    return indent_list({ dedent = true })
end, { expr = true, buffer = true })
vim.keymap.set('n', '<Leader>ct', toggle_checklist, { buffer = true })
--- Sphinx (html)
vim.keymap.set('n', '<Leader>bh', build_sphinx_docs, { buffer = true })
vim.keymap.set('n', '<Leader>vh', view_sphinx_docs, { buffer = true })
