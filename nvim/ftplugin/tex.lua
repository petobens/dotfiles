local overseer = require('overseer')
local scan = require('plenary.scandir')
local u = require('utils')

-- Options (note: some other options are in /after/ftplugin file)
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.iskeyword = '@,48-57,_,192-255,:'

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
    if vim.fn.filereadable(filename) == 0 then
        return
    end
    local content = require('overseer.files').read_file(filename)
    local lines = vim.split(content, '\n')
    local items = vim.fn.getqflist({
        lines = lines,
        efm = LATEX_EFM,
    }).items

    local new_qf = {}
    for _, v in pairs(items) do
        -- TODO: Find a better way of ignoring warnings (i.e with efm)
        if not string.find(v.text, 'lipsum') then
            table.insert(new_qf, v)
        end
    end
    vim.fn.setqflist({}, ' ', {
        title = filename,
        items = new_qf,
    })
    vim.cmd('lcd ' .. cwd)
    if next(new_qf) ~= nil then
        vim.cmd('copen')
        vim.fn.win_gotoid(active_window_id)
    end
end

local function compile_latex()
    local cwd = vim.fn.getcwd()
    local current_win_id = vim.fn.win_getid()
    vim.cmd('silent noautocmd update')
    vim.cmd('lcd %:p:h') -- we seem to need this for proper qf parsing
    overseer.run_template({ name = 'run_arara' }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            local log_file = vim.fn.fnamemodify(task.metadata.filename, ':p:r') .. '.log'
            _parse_logfile(log_file, cwd, current_win_id)
        end)
    end)
end

-- Viewing
local function view_pdf()
    local pdf_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:r') .. '.pdf'
    vim.fn.jobstart('zathura --fork ' .. pdf_file)
end

local function forward_search()
    local tex_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
    local pdf_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:r') .. '.pdf'
    local forward_args = ' --synctex-forward '
        .. vim.fn.line('.')
        .. ':'
        .. vim.fn.col('.')
        .. ':'
        .. tex_file
        .. ' '
        .. pdf_file
    vim.fn.jobstart('zathura ' .. forward_args)
end

-- File Editing
local function file_edit(search_file)
    local base_dir = vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:h')
    local base_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':t:r')

    if search_file == 'bib' or search_file == 'log' then
        search_file = string.format('%s.%s', base_file, search_file)
    elseif search_file == 'float' then
        search_file = vim.fn.fnamemodify(
            string.match(vim.fn.expand('<cWORD>'), '{(%S+)}'),
            ':t:r'
        ) .. '.tex'
    end
    local edit_file = vim.fs.find({ search_file }, {
        type = 'file',
        path = base_dir,
    })

    local split = 'split '
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd(split .. edit_file[1])
end

-- Miscellaneous
local function delete_aux_files()
    local aux_extensions = {
        'aux',
        'bbl',
        'bcf',
        'blg',
        'idx',
        'log',
        'xml',
        'toc',
        'nav',
        'out',
        'snm',
        'gz',
        'ilg',
        'ind',
        'vrb',
        'log',
    }
    local files = scan.scan_dir(vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:h'))
    local rm_files = {}
    for _, f in pairs(files) do
        local ext = vim.fn.fnamemodify(f, ':e')
        for _, aux_ext in pairs(aux_extensions) do
            if ext == aux_ext then
                table.insert(rm_files, f)
            end
        end
    end
    vim.ui.input(
        { prompt = string.format('Delete %s files? [y/n] ', #rm_files) },
        function(input)
            if input == 'y' then
                for _, f in pairs(rm_files) do
                    vim.fn.jobstart('trash-put ' .. f)
                end
            end
        end
    )
end

local function convert_pandoc(extension)
    local base_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':t:r')
    local output_file = string.format('%s.%s', base_file, extension)
    local bib_file = base_file .. '.bib'

    local pandoc_cmd = 'pandoc -s'
    if extension == 'docx' then
        pandoc_cmd = pandoc_cmd .. ' --toc --number-sections'
        if vim.fn.filereadable(bib_file) > 0 then
            pandoc_cmd = pandoc_cmd .. ' --bibliography=' .. bib_file
        end
    end

    pandoc_cmd = string.format('%s %s.tex -o %s', pandoc_cmd, base_file, output_file)
    vim.fn.system(pandoc_cmd)
    if vim.v.shell_error ~= 1 then
        vim.cmd.echo(string.format('"Converted .tex file into .%s"', extension))
    end
end

-- Mappings
---- Compilation
u.keymap('n', '<F7>', compile_latex, { buffer = true })
u.keymap('i', '<F7>', compile_latex, { buffer = true })
u.keymap('n', '<Leader>vp', view_pdf, { buffer = true })
u.keymap('n', '<Leader>sl', forward_search, { buffer = true })
u.keymap('n', '<Leader>da', delete_aux_files, { buffer = true })
u.keymap('n', '<Leader>cm', function()
    convert_pandoc('md')
end, { buffer = true })
u.keymap('n', '<Leader>cx', function()
    convert_pandoc('docx')
end, { buffer = true })
---- Editing
u.keymap('n', '<Leader>em', function()
    file_edit('main.tex')
end, { buffer = true })
u.keymap('n', '<Leader>ep', function()
    file_edit('preamble.tex')
end, { buffer = true })
u.keymap('n', '<Leader>eb', function()
    file_edit('bib')
end, { buffer = true })
u.keymap('n', '<Leader>el', function()
    file_edit('log')
end, { buffer = true })
u.keymap('n', '<Leader>ef', function()
    file_edit('float')
end, { buffer = true })
---- Tables
u.keymap('i', '<A-c>', '<ESC>f&lli', { buffer = true })
u.keymap('i', '<A-r>', '<ESC>j0f&hi', { buffer = true })
