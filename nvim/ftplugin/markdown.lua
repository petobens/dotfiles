local overseer = require('overseer')

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
                vim.cmd.normal({ args = { 'zx' }, bang = true })
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
        local num = tonumber(marker:match('%d+'))
        marker = (num + 1) .. '. '
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
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode
    local start_line, end_line
    if mode:match('^v') or mode:match('^V') then
        start_line = vim.fn.line('v')
        end_line = vim.fn.line('.')
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
    else
        start_line = vim.fn.line('.')
        end_line = start_line
    end

    local next_state = {
        [' '] = '_',
        ['_'] = 'x',
        ['x'] = '~',
        ['~'] = ' ',
    }
    local checkbox_pat = '(%[([ %_x~])%])'

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub(checkbox_pat, function(box, state)
            local new_state = next_state[state]
            if new_state then
                return '[' .. new_state .. ']'
            else
                return box
            end
        end, 1)
    end
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
end

---- Pandoc
local function convert_pandoc(extension)
    local msg = 'Converting markdown file with pandoc...'
    local on_exit = function(obj)
        if obj.code == 0 then
            vim.print(msg .. 'done!')
        else
            vim.print(obj.stderr)
            vim.print(msg .. 'failed!')
        end
    end

    local base_file = vim.fs.normalize(vim.api.nvim_buf_get_name(0)):match('(.+)%.[^/]+$')
    local output_file = string.format('%s.%s', base_file, extension)
    vim.print(msg)
    vim.system({
        'pandoc',
        '-s',
        '--toc',
        '--number-sections',
        base_file .. '.md',
        '-o',
        output_file,
    }, { text = true }, on_exit)
end

---- Sphinx
local function run_sphinx_build()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    overseer.run_template({ name = 'run_sphinx_build' }, function()
        vim.cmd.cclose()
    end)
end

local function clean_sphinx_build()
    local on_exit = function(obj)
        if obj.code == 0 then
            vim.print('Cleaning sphinx html build... done!')
        else
            vim.print(obj.stderr)
        end
    end

    local project_root = vim.fs.root(0, 'pyproject.toml')
    vim.print('Cleaning sphinx html build...')
    local package_manager = (
        next(_G.PyVenv.active_venv) and _G.PyVenv.active_venv.package_manager
    ) or 'uv'
    vim.system(
        { package_manager, 'run', 'make', 'clean' },
        { cwd = vim.fs.joinpath(project_root, 'docs'), text = true },
        on_exit
    )
end

local function view_sphinx_docs()
    local project_root = vim.fs.root(0, 'pyproject.toml') or vim.uv.cwd()
    local docs_dir = vim.fs.joinpath(project_root, 'docs', 'build', 'html')
    local html_file = vim.fs.joinpath(docs_dir, 'index.html')
    vim.ui.open(html_file)
end

-- Mappings
---- Compiling
vim.keymap.set('n', '<F8>', function()
    convert_pandoc('pdf')
end, { buffer = true })
vim.keymap.set('n', '<F9>', function()
    convert_pandoc('html')
end, { buffer = true })
vim.keymap.set('n', '<Leader>vp', function()
    vim.system({
        'zathura',
        '--fork',
        vim.fs.normalize(vim.api.nvim_buf_get_name(0)):match('(.+)%.[^/]+$') .. '.pdf',
    })
end, { buffer = true })
---- Lists
vim.keymap.set('i', '<CR>', continue_list, { expr = true, buffer = true })
vim.keymap.set('i', '<Tab>', indent_list, { expr = true, buffer = true })
vim.keymap.set('i', '<S-Tab>', function()
    return indent_list({ dedent = true })
end, { expr = true, buffer = true })
vim.keymap.set({ 'n', 'v' }, '<Leader>ct', toggle_checklist, { buffer = true })
--- Sphinx (html)
vim.keymap.set('n', '<F7>', run_sphinx_build, { buffer = true })
vim.keymap.set('n', '<Leader>da', clean_sphinx_build, { buffer = true })
vim.keymap.set('n', '<Leader>vd', view_sphinx_docs, { buffer = true })
--- Math rendering
vim.keymap.set('n', '<Leader>vm', require('nabla').popup, { buffer = true })
--- TOC
vim.keymap.set('n', '<Leader>tc', 'gO', { buffer = true, remap = true })
