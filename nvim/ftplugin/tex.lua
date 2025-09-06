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

local function _parse_logfile(filename, cwd, active_window_id)
    local stat = vim.uv.fs_stat(filename)
    if not (stat and stat.type == 'file') then
        return
    end
    local content = require('overseer.files').read_file(filename)
    local lines = vim.split(content, '\n')
    local items = vim.fn.getqflist({
        lines = lines,
        efm = LATEX_EFM,
    }).items

    local new_qf = {}
    for _, v in ipairs(items) do
        -- TODO: Find a better way of ignoring warnings (i.e with efm)
        if not string.find(v.text, 'lipsum') then
            table.insert(new_qf, v)
        end
    end
    vim.fn.setqflist({}, ' ', {
        title = filename,
        items = new_qf,
    })
    vim.cmd.lcd({ args = { cwd } })
    if #new_qf > 0 then
        vim.cmd.copen()
        vim.api.nvim_set_current_win(active_window_id)
    end
end

local function compile_latex()
    local cwd = vim.uv.cwd()
    local current_win_id = vim.api.nvim_get_current_win()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    -- We seem to need the following for proper qf parsing
    vim.cmd.lcd({ args = { vim.fs.dirname(vim.api.nvim_buf_get_name(0)) } })
    overseer.run_template({ name = 'run_arara' }, function(task)
        vim.cmd.cclose()
        task:subscribe('on_complete', function()
            local log_file = (vim.fs.normalize(task.metadata.filename)):match(
                '(.+)%.[^/]+$'
            ) .. '.log'
            _parse_logfile(log_file, cwd, current_win_id)
        end)
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
            local ext = f:match('%.([^/%.]+)$')
            if ext and aux_extensions[ext] then
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
    { buffer = true, desc = 'Compile LaTeX (arara)' }
)
vim.keymap.set(
    'n',
    '<Leader>vp',
    view_pdf,
    { buffer = true, desc = 'View PDF in Zathura' }
)
vim.keymap.set(
    'n',
    '<Leader>sl',
    forward_search,
    { buffer = true, desc = 'Forward search (synctex)' }
)
vim.keymap.set(
    'n',
    '<Leader>da',
    delete_aux_files,
    { buffer = true, desc = 'Delete auxiliary files' }
)
vim.keymap.set('n', '<Leader>cm', function()
    convert_pandoc('md')
end, { buffer = true, desc = 'Convert to Markdown (pandoc)' })
vim.keymap.set('n', '<Leader>cx', function()
    convert_pandoc('docx')
end, { buffer = true, desc = 'Convert to DOCX (pandoc)' })

---- Editing
vim.keymap.set('n', '<Leader>em', function()
    file_edit('main.tex')
end, { buffer = true, desc = 'Edit main.tex' })
vim.keymap.set('n', '<Leader>ep', function()
    file_edit('preamble.tex')
end, { buffer = true, desc = 'Edit preamble.tex' })
vim.keymap.set('n', '<Leader>eb', function()
    file_edit('bib')
end, { buffer = true, desc = 'Edit bibliography' })
vim.keymap.set('n', '<Leader>el', function()
    file_edit('log')
end, { buffer = true, desc = 'Edit log file' })
vim.keymap.set('n', '<Leader>ef', function()
    file_edit('float')
end, { buffer = true, desc = 'Edit float file' })

---- Tables
vim.keymap.set('i', '<A-c>', '<ESC>f&lli', { buffer = true, desc = 'Table: next column' })
vim.keymap.set('i', '<A-r>', '<ESC>j0f&hi', { buffer = true, desc = 'Table: next row' })

---- Lists
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buffer = true, desc = 'Continue LaTeX list' }
)
