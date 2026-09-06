local overseer = require('overseer')
local u = require('utils')

-- Options (note: some other options are in /after/ftplugin file)
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.iskeyword = '@,48-57,_,192-255,:'
vim.opt_local.formatexpr = ''

-- Compiling
local LATEX_EFM = ''
    -- From https://github.com/lervag/vimtex/blob/master/autoload/vimtex/qf/latexlog.vim
    -- Push file to file stack
    .. [[%-P**%f,]]
    .. [[%-P**\"%f\",]]
    -- Match errors
    .. [[%E!\ LaTeX\ %trror:\ %m,]]
    .. [[%E%f:%l:\ %m,]]
    .. [[%E!\ %m,]]
    -- More info for undefined control sequences
    .. [[%Z<argument>\ %m,]]
    -- More info for some errors
    .. [[%Cl.%l\ %m,]]
    -- Show warnings (some warnings)
    .. [[%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#,]]
    .. [[%+W%.%#\ at\ lines\ %l--%*\\d,]]
    .. [[%+WLaTeX\ %.%#Warning:\ %m,]]
    .. [[%+W%.%#%.%#Warning:\ %m,]]
    .. [[%-C(biblatex)%.%#in\ t%.%#,]]
    .. [[%-C(biblatex)%.%#Please\ v%.%#,]]
    .. [[%-C(biblatex)%.%#LaTeX\ a%.%#,]]
    .. [[%-Z(biblatex)%m,]]
    .. [[%-Z(babel)%.%#input\ line\ %l.,]]
    .. [[%-C(babel)%m,]]
    .. [[%-C(hyperref)%.%#on\ input\ line\ %l.,]]
    -- Ignore refsection and float warnings
    .. [[%-G%.%#refsection%.%#,]]
    .. [[%-G%.%#contains\ only\ floats%.%#,]]
    -- Ignore unmatched lines
    .. [[%-G%.%#,]]

local function _parse_logfile(filename, active_window_id)
    local stat = vim.uv.fs_stat(filename)
    if not (stat and stat.type == 'file') then
        return false
    end
    local content = require('overseer.files').read_file(filename)
    local lines = vim.split(content, '\n')
    local items = vim.fn.getqflist({
        lines = lines,
        efm = LATEX_EFM,
    }).items

    local has_errors = false
    local new_qf = {}
    for _, v in ipairs(items) do
        -- TODO: Find a better way of ignoring warnings (i.e with efm)
        if not string.find(v.text, 'lipsum') then
            table.insert(new_qf, v)
            has_errors = has_errors or v.type == 'E'
        end
    end
    vim.fn.setqflist({}, ' ', {
        title = filename,
        items = new_qf,
    })
    if #new_qf > 0 then
        vim.cmd.copen()
        vim.api.nvim_set_current_win(active_window_id)
    end
    return has_errors
end

local function compile_latex()
    local cwd = vim.uv.cwd()
    local current_win_id = vim.api.nvim_get_current_win()
    local log_file = (vim.fs.normalize(vim.b.vimtex.tex)):match('(.+)%.[^/]+$') .. '.log'
    local previous_log_stat = vim.uv.fs_stat(log_file)
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    -- We seem to need the following for proper qf parsing
    vim.cmd.lcd({ args = { vim.fs.dirname(vim.api.nvim_buf_get_name(0)) } })
    overseer.run_task({ name = 'run_arara', autostart = false }, function(task)
        vim.cmd.cclose()
        task:subscribe('on_complete', function(_, status)
            -- Overseer flushes its terminal buffer on the next event-loop turn
            vim.schedule(function()
                local log_stat = vim.uv.fs_stat(log_file)
                local log_changed = log_stat
                    and (
                        not previous_log_stat
                        or log_stat.size ~= previous_log_stat.size
                        or not vim.deep_equal(log_stat.mtime, previous_log_stat.mtime)
                    )
                local has_latex_errors = log_changed
                    and _parse_logfile(log_file, current_win_id)
                vim.cmd.lcd({ args = { cwd } })
                if status ~= overseer.STATUS.FAILURE or has_latex_errors then
                    return
                end
                local output_buf = task:get_bufnr()
                if not output_buf then
                    return
                end
                local items = {}
                local output = vim.api.nvim_buf_get_lines(output_buf, 0, -1, false)
                for _, text in ipairs(output) do
                    if text ~= '' then
                        table.insert(items, { text = text })
                    end
                end
                vim.fn.setqflist({}, ' ', { title = 'Arara', items = items })
                vim.cmd.copen()
                vim.api.nvim_set_current_win(current_win_id)
            end)
        end)
        task:start()
    end)
end

-- Viewing
local function view_pdf()
    local base = vim.fs.normalize(vim.b.vimtex.tex):match('(.+)%.[^/]+$')
    local pdf_file = base and (base .. '.pdf') or nil
    if not pdf_file or not vim.uv.fs_stat(pdf_file) then
        vim.notify('PDF file not found: ' .. tostring(pdf_file), vim.log.levels.ERROR)
        return
    end
    vim.system({ 'zathura', '--fork', pdf_file })
end

local function forward_search()
    local tex_file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    local base = vim.fs.normalize(vim.b.vimtex.tex):match('(.+)%.[^/]+$')
    local pdf_file = base and (base .. '.pdf') or nil
    if not pdf_file or not vim.uv.fs_stat(pdf_file) then
        vim.notify('PDF file not found: ' .. tostring(pdf_file), vim.log.levels.ERROR)
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1 -- col is 0-based in API, but synctex expects 1-based
    local synctex_cmd = {
        'zathura',
        '--synctex-forward',
        string.format('%d:%d:%s', line, col, tex_file),
        pdf_file,
    }
    vim.system(synctex_cmd)
end

-- File Editing
local function file_edit(search_file)
    local base_dir = vim.fs.dirname(vim.b.vimtex.tex)
    local base_file = (vim.fs.basename(vim.b.vimtex.tex)):match('(.+)%.[^/]+$')

    if search_file == 'bib' or search_file == 'log' then
        search_file = string.format('%s.%s', base_file, search_file)
    elseif search_file == 'float' then
        local match = string.match(vim.fn.expand('<cWORD>'), '{(%S+)}')
        search_file = vim.fs.basename(match or ''):gsub('%.%w+$', '') .. '.tex'
    end
    local edit_file = vim.fs.find({ search_file }, {
        type = 'file',
        path = base_dir,
    })
    if not edit_file[1] then
        vim.notify('File not found: ' .. search_file, vim.log.levels.ERROR)
        return
    end
    u.split_open(edit_file[1])
end

-- Miscellaneous
local function delete_aux_files()
    local aux_extensions = {
        aux = true,
        bbl = true,
        bcf = true,
        blg = true,
        idx = true,
        log = true,
        xml = true,
        toc = true,
        nav = true,
        out = true,
        snm = true,
        gz = true,
        ilg = true,
        ind = true,
        vrb = true,
    }
    local dir = vim.fs.dirname(vim.b.vimtex.tex)
    local rm_files = {}
    for name, type in vim.fs.dir(dir) do
        if type == 'file' then
            local f = vim.fs.joinpath(dir, name)
            if aux_extensions[vim.fs.ext(f)] then
                table.insert(rm_files, f)
            end
        end
    end
    if #rm_files == 0 then
        vim.notify('No auxiliary files found to delete', vim.log.levels.INFO)
        return
    end

    vim.ui.input(
        { prompt = string.format('Delete %d auxiliary files? [y/n] ', #rm_files) },
        function(input)
            if input == 'y' then
                for _, f in ipairs(rm_files) do
                    vim.system({ 'trash-put', f }):wait()
                end
                vim.notify(
                    string.format('Deleted %d auxiliary files', #rm_files),
                    vim.log.levels.INFO
                )
            end
        end
    )
end

local function convert_pandoc(extension)
    local tex_path = vim.fs.normalize(vim.b.vimtex.tex)
    local base_file = tex_path:match('(.+)%.[^/]+$')
    local tex_file = base_file .. '.tex'
    local output_file = string.format('%s.%s', base_file, extension)
    local bib_file = base_file .. '.bib'
    if not vim.uv.fs_stat(tex_file) then
        vim.notify('TeX file not found: ' .. tex_file, vim.log.levels.ERROR)
        return
    end

    local pandoc_cmd = 'pandoc -s'
    if extension == 'docx' then
        pandoc_cmd = pandoc_cmd .. ' --toc --number-sections'
        if vim.uv.fs_stat(bib_file) then
            pandoc_cmd = pandoc_cmd .. ' --bibliography=' .. bib_file
        end
    end
    pandoc_cmd = string.format('%s %s -o %s', pandoc_cmd, tex_file, output_file)

    local cwd = vim.fs.dirname(tex_file)
    local args = vim.split(pandoc_cmd, ' ', { trimempty = true })
    local result = vim.system(args, { text = true, cwd = cwd }):wait()
    if result.code == 0 then
        vim.notify(
            string.format('Converted .tex file into .%s', extension),
            vim.log.levels.INFO
        )
    else
        vim.notify(
            string.format(
                'Pandoc failed (exit code %d): %s',
                result.code,
                result.stderr or ''
            ),
            vim.log.levels.ERROR
        )
    end
end

local function continue_list()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    line = line:match('^%s*(.*)$') or ''
    local marker = line:match('^(\\item%s*)')
    if not marker or line == '' then
        return '<CR>'
    end
    if line == marker then
        return '<C-U>'
    end
    return '<CR>' .. marker
end

-- Mappings
---- Compilation
vim.keymap.set(
    { 'n', 'i' },
    '<F7>',
    compile_latex,
    { buf = 0, desc = 'Compile LaTeX (arara)' }
)
vim.keymap.set('n', '<Leader>vp', view_pdf, {
    buf = 0,
    desc = '[V]iew PDF [p]review in Zathura',
})
vim.keymap.set(
    'n',
    '<Leader>sl',
    forward_search,
    { buf = 0, desc = '[S]yncTeX forward search to PDF [l]ocation' }
)
vim.keymap.set(
    'n',
    '<Leader>da',
    delete_aux_files,
    { buf = 0, desc = '[D]elete [a]uxiliary files' }
)
vim.keymap.set('n', '<Leader>cm', function()
    convert_pandoc('md')
end, { buf = 0, desc = '[C]onvert to [m]arkdown (Pandoc)' })
vim.keymap.set('n', '<Leader>cx', function()
    convert_pandoc('docx')
end, { buf = 0, desc = '[C]onvert to DOC[x] (Pandoc)' })

---- Editing
vim.keymap.set('n', '<Leader>em', function()
    file_edit('main.tex')
end, { buf = 0, desc = '[E]dit [m]ain.tex' })
vim.keymap.set('n', '<Leader>ep', function()
    file_edit('preamble.tex')
end, { buf = 0, desc = '[E]dit [p]reamble.tex' })
vim.keymap.set('n', '<Leader>eb', function()
    file_edit('bib')
end, { buf = 0, desc = '[E]dit [b]ibliography' })
vim.keymap.set('n', '<Leader>el', function()
    file_edit('log')
end, { buf = 0, desc = '[E]dit [l]og file' })
vim.keymap.set('n', '<Leader>ef', function()
    file_edit('float')
end, { buf = 0, desc = '[E]dit [f]loat file' })

---- Tables
vim.keymap.set('i', '<A-c>', '<ESC>f&lli', { buf = 0, desc = 'Table: next column' })
vim.keymap.set('i', '<A-r>', '<ESC>j0f&hi', { buf = 0, desc = 'Table: next row' })

---- Lists
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buf = 0, desc = 'Continue LaTeX list' }
)
