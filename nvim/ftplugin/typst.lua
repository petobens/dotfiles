-- Options
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.textwidth = 80
vim.opt_local.formatexpr = ''
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = vim.treesitter.foldexpr
vim.opt_local.foldtext = ''

-- Paths
local function project_root(source)
    local root = vim.fs.root(source, '.typst-root') or vim.fs.root(source, '.git')
    return root or vim.fs.dirname(source), root ~= nil
end

local function main_source(source)
    local root, has_root = project_root(source)
    local main = vim.fs.find('main.typ', {
        path = vim.fs.dirname(source),
        stop = has_root and vim.fs.dirname(root) or nil,
        type = 'file',
        upward = true,
    })[1]
    return main or source
end

local function document_paths()
    local current = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    if current == '' then
        return nil, nil, 'Save the Typst file before compiling'
    end

    local source = main_source(current)
    local base = source:match('(.+)%.[^/]+$')
    return source, base and (base .. '.pdf') or nil
end

_G.TypstConfig = {
    main_source = main_source,
    project_root = project_root,
}

-- Compilation
local function clear_typst_errors()
    if vim.fn.getqflist({ title = 1 }).title == 'Typst' then
        vim.fn.setqflist({}, 'r')
        vim.cmd.cclose()
    end
end

local function compile_typst(notify_success)
    if vim.fn.executable('typst') == 0 then
        vim.notify('Typst executable not found', vim.log.levels.ERROR)
        return
    end

    local source, pdf, path_error = document_paths()
    if not source or not pdf then
        vim.notify(
            path_error or 'Cannot determine Typst output path',
            vim.log.levels.ERROR
        )
        return
    end

    local root = project_root(source)
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.system(
        {
            'typst',
            'compile',
            '--root',
            root,
            '--diagnostic-format',
            'short',
            source,
            pdf,
        },
        { cwd = root, text = true },
        vim.schedule_wrap(function(result)
            if result.code == 0 then
                clear_typst_errors()
                if notify_success then
                    vim.notify('Compiled ' .. vim.fs.basename(pdf), vim.log.levels.INFO)
                end
                return
            end

            local stderr = vim.trim(result.stderr or '')
            local items = {}
            for line in stderr:gmatch('[^\n]+') do
                local file, lnum, col, severity, message =
                    line:match('^(.-):(%d+):(%d+): (%a+): (.+)$')
                if file then
                    if not vim.startswith(file, '/') then
                        file = vim.fs.normalize(vim.fs.joinpath(root, file))
                    end
                    table.insert(items, {
                        filename = file,
                        lnum = tonumber(lnum),
                        col = tonumber(col),
                        type = severity == 'warning' and 'W' or 'E',
                        text = message,
                    })
                end
            end
            if #items > 0 then
                vim.fn.setqflist({}, ' ', { title = 'Typst', items = items })
                vim.cmd.copen()
            else
                vim.notify(
                    stderr ~= '' and stderr or 'Typst compilation failed',
                    vim.log.levels.ERROR
                )
            end
        end)
    )
end

-- PDF viewer
local function view_pdf()
    local _, pdf, path_error = document_paths()
    if path_error then
        vim.notify(path_error, vim.log.levels.ERROR)
        return
    end
    if not pdf or not vim.uv.fs_stat(pdf) then
        vim.notify('PDF file not found: ' .. tostring(pdf), vim.log.levels.ERROR)
        return
    end
    vim.system({ 'zathura', '--fork', pdf })
end

-- Editing
local function edit_main()
    local current = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    if current == '' then
        vim.notify(
            'Save the Typst file before opening its main file',
            vim.log.levels.ERROR
        )
        return
    end
    local split = 'split'
    if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit'
    end
    vim.api.nvim_cmd({
        cmd = split,
        args = { main_source(current) },
        magic = { file = false, bar = false },
    }, {})
end

local function continue_list()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    local indent, marker = line:match('^(%s*)([-+]%s+)')
    if not marker then
        return '<CR>'
    end
    if line == indent .. marker then
        return '<C-U>'
    end
    return '<CR>' .. marker
end

-- Autocmds
vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = 0,
    desc = 'Compile Typst document outside packages',
    callback = function(args)
        if not vim.fs.root(args.buf, 'typst.toml') then
            compile_typst(false)
        end
    end,
})

-- Mappings
vim.keymap.set({ 'n', 'i' }, '<F7>', function()
    compile_typst(true)
end, { buf = 0, desc = 'Compile Typst document' })
vim.keymap.set('n', '<Leader>vp', view_pdf, { buf = 0, desc = 'View PDF in Zathura' })
vim.keymap.set('n', '<Leader>em', edit_main, { buf = 0, desc = 'Edit main.typ' })
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buf = 0, desc = 'Continue Typst list' }
)
