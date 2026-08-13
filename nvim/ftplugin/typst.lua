-- Options
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.spell = true
vim.opt_local.textwidth = 80
vim.opt_local.formatexpr = ''
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = vim.treesitter.foldexpr
vim.opt_local.foldtext = ''

-- Paths
local function document_paths()
    local source = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    local base = source:match('(.+)%.[^/]+$')
    local output = vim.iter(vim.api.nvim_buf_get_lines(0, 0, 10, false))
        :map(function(line)
            return line:match('^//%s*output:%s*(.-)%s*$')
        end)
        :find(function(path)
            return path ~= ''
        end)
    local pdf = output and vim.fs.joinpath(vim.fs.dirname(source), output)
        or (base and (base .. '.pdf') or nil)
    return source, pdf
end

local function project_root(source)
    local marker = vim.fs.find('.typst-root', {
        path = vim.fs.dirname(source),
        upward = true,
    })[1] or vim.fs.find('.git', {
        path = vim.fs.dirname(source),
        upward = true,
    })[1]
    return marker and vim.fs.dirname(marker) or vim.fs.dirname(source)
end

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

    local source, pdf = document_paths()
    if source == '' or not pdf then
        vim.notify('Save the Typst file before compiling', vim.log.levels.ERROR)
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
                        file = vim.fs.joinpath(vim.fs.dirname(source), file)
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
    local _, pdf = document_paths()
    if not pdf or not vim.uv.fs_stat(pdf) then
        vim.notify('PDF file not found: ' .. tostring(pdf), vim.log.levels.ERROR)
        return
    end
    vim.system({ 'zathura', '--fork', pdf })
end

-- Editing
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

-- Mappings and autocmds
vim.keymap.set({ 'n', 'i' }, '<F7>', function()
    compile_typst(true)
end, { buf = 0, desc = 'Compile Typst document' })
vim.keymap.set('n', '<Leader>vp', view_pdf, { buf = 0, desc = 'View PDF in Zathura' })
vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = 0,
    desc = 'Compile Typst document',
    callback = function()
        compile_typst(false)
    end,
})
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buf = 0, desc = 'Continue Typst list' }
)
