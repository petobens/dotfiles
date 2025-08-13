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
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        desc = 'Refresh markdown folds',
        group = vim.api.nvim_create_augroup('md_folds', { clear = true }),
        pattern = { '*.md' },
        callback = function()
            -- If a choice node is active then `zx` is inserted so avoid that case
            if not require('luasnip').choice_active() then
                vim.cmd.normal({ args = { 'zx' }, bang = true })
            end
        end,
    }
)

-- Functions
---- Lists
local function continue_list()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    line = line:match('^%s*(.*)$') or ''

    local unordered = line:match('^([*-]%s)')
    local task = line:match('^([*-]%s%[%s?%]%s)')
    local blockquote = line:match('^(>%s)')
    local ordered = line:match('^(%d+)%.%s')

    local marker
    if task then
        marker = task
    elseif unordered then
        marker = unordered
    elseif blockquote then
        marker = blockquote
    elseif ordered then
        marker = tostring(tonumber(ordered) + 1) .. '. '
    end

    if not marker or line == '' then
        return '<CR>'
    end
    if line == marker then
        return '<C-U>'
    end
    return '<CR>' .. marker
end

local function toggle_checklist()
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode
    local start_line, end_line

    if mode:sub(1, 1) == 'v' or mode:sub(1, 1) == 'V' then
        start_line = vim.api.nvim_buf_get_mark(bufnr, '<')[1]
        end_line = vim.api.nvim_buf_get_mark(bufnr, '>')[1]
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
    else
        start_line = vim.api.nvim_win_get_cursor(0)[1]
        end_line = start_line
    end

    local next_state = { [' '] = '_', ['_'] = 'x', ['x'] = '~', ['~'] = ' ' }
    local checkbox_pat = '(%[([ %_x~])%])' -- Lua pattern for [ ] [x] [_] [~]

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub(checkbox_pat, function(box, state)
            local new_state = next_state[state]
            return new_state and ('[' .. new_state .. ']') or box
        end, 1)
    end
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
end

---- Pandoc
local function convert_pandoc(extension)
    local bufname = vim.api.nvim_buf_get_name(0)
    local dir = vim.fs.dirname(bufname)
    local base = vim.fs.basename(bufname):gsub('%.md$', '')
    local output_file = vim.fs.joinpath(dir, base .. '.' .. extension)

    vim.notify('Converting markdown file with pandoc...', vim.log.levels.INFO)
    vim.system({
        'pandoc',
        '-s',
        '--toc',
        '--number-sections',
        bufname,
        '-o',
        output_file,
    }, { text = true }, function(obj)
        if obj.code == 0 then
            vim.print('Converting markdown file with pandoc... done!')
        else
            vim.print(obj.stderr or 'Pandoc failed!')
        end
    end)
end

---- Sphinx
local function run_sphinx_build()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    overseer.run_template({ name = 'run_sphinx_build' }, function()
        vim.cmd.cclose()
    end)
end

local function clean_sphinx_build()
    local project_root = vim.fs.root(0, 'pyproject.toml')
    local docs_dir = vim.fs.joinpath(project_root, 'docs')
    local package_manager = 'uv'
    if _G.PyVenv and _G.PyVenv.active_venv and _G.PyVenv.active_venv.package_manager then
        package_manager = _G.PyVenv.active_venv.package_manager
    end

    vim.notify('Cleaning sphinx html build...', vim.log.levels.INFO)
    vim.system(
        { package_manager, 'run', 'make', 'clean' },
        { cwd = docs_dir, text = true },
        function(obj)
            if obj.code == 0 then
                vim.print('Cleaning sphinx html build... done!')
            else
                vim.print(obj.stderr or 'Sphinx clean failed!')
            end
        end
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
end, { buffer = true, desc = 'Convert markdown to PDF (pandoc)' })

vim.keymap.set('n', '<F9>', function()
    convert_pandoc('html')
end, { buffer = true, desc = 'Convert markdown to HTML (pandoc)' })

vim.keymap.set('n', '<Leader>vp', function()
    vim.system({
        'zathura',
        '--fork',
        vim.fs.normalize(vim.api.nvim_buf_get_name(0)):match('(.+)%.[^/]+$') .. '.pdf',
    })
end, { buffer = true, desc = 'View PDF in Zathura' })

---- Lists
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buffer = true, desc = 'Continue markdown list' }
)

vim.keymap.set(
    { 'n', 'v' },
    '<Leader>ct',
    toggle_checklist,
    { buffer = true, desc = 'Toggle checklist state' }
)

--- Sphinx (html)
vim.keymap.set(
    'n',
    '<F7>',
    run_sphinx_build,
    { buffer = true, desc = 'Build Sphinx docs' }
)

vim.keymap.set(
    'n',
    '<Leader>da',
    clean_sphinx_build,
    { buffer = true, desc = 'Clean Sphinx build' }
)

vim.keymap.set(
    'n',
    '<Leader>vd',
    view_sphinx_docs,
    { buffer = true, desc = 'View Sphinx HTML docs' }
)

--- Misc
vim.keymap.set(
    'n',
    '<Leader>vm',
    require('nabla').popup,
    { buffer = true, desc = 'Render math with Nabla' }
)

vim.keymap.set(
    'n',
    '<Leader>tc',
    'gO',
    { buffer = true, remap = true, desc = 'Insert TOC' }
)
