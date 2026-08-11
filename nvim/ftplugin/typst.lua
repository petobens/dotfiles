vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.spell = true
vim.opt_local.textwidth = 80
vim.opt_local.formatexpr = ''

local function document_paths()
    local source = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    local base = source:match('(.+)%.[^/]+$')
    return source, base and (base .. '.pdf') or nil
end

local function compile_typst()
    if vim.fn.executable('typst') == 0 then
        vim.notify('Typst executable not found', vim.log.levels.ERROR)
        return
    end

    local source, pdf = document_paths()
    if source == '' or not pdf then
        vim.notify('Save the Typst file before compiling', vim.log.levels.ERROR)
        return
    end

    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.system(
        { 'typst', 'compile', '--diagnostic-format', 'short', source, pdf },
        { cwd = vim.fs.dirname(source), text = true },
        vim.schedule_wrap(function(result)
            vim.cmd.cclose()
            if result.code == 0 then
                vim.notify('Compiled ' .. vim.fs.basename(pdf), vim.log.levels.INFO)
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

local function view_pdf()
    local _, pdf = document_paths()
    if not pdf or not vim.uv.fs_stat(pdf) then
        vim.notify('PDF file not found: ' .. tostring(pdf), vim.log.levels.ERROR)
        return
    end
    vim.system({ 'zathura', '--fork', pdf })
end

vim.keymap.set(
    { 'n', 'i' },
    '<F7>',
    compile_typst,
    { buf = 0, desc = 'Compile Typst document' }
)
vim.keymap.set('n', '<Leader>vp', view_pdf, { buf = 0, desc = 'View PDF in Zathura' })
