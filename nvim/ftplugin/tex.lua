local overseer = require('overseer')
local scan = require('plenary.scandir')
local u = require('utils')

-- Options
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.iskeyword = '@,48-57,_,192-255,:'
vim.opt_local.indentkeys = '!^F,o,O,0=\\item'
vim.opt_local.comments = vim.opt.comments + { 'b:\\item' }

-- Compiling
local LATEX_EFM = ''
    -- Push file to file stack
    .. [[%-P**%f,]]
    .. [[%-P**\"%f\",]]
    -- Match errors
    .. [[%E!\ LaTeX\ %trror:\ %m,]]
    .. [[%E%f:%l:\ %m,]]
    .. [[%E!\ %m,]]
    -- More info for undefined control sequences
    .. [[%Z<argument>\ %m,]]
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

local _parse_logfile = function(filename, cwd, active_window_id)
    local content = require('overseer.files').read_file(filename)
    local lines = vim.split(content, '\n')
    local items = vim.fn.getqflist({
        lines = lines,
        efm = LATEX_EFM,
    }).items
    vim.fn.setqflist({}, ' ', {
        title = filename,
        items = items,
    })
    vim.cmd('lcd ' .. cwd)
    if next(items) ~= nil then
        vim.cmd('copen')
        vim.fn.win_gotoid(active_window_id)
    end
end

local compile_latex = function()
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
local view_pdf = function()
    local pdf_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:r') .. '.pdf'
    vim.fn.jobstart('zathura --fork ' .. pdf_file)
end

local forward_search = function()
    local tex_file = vim.b.vimtex.tex
    local pdf_file = vim.fn.fnamemodify(tex_file, ':p:r') .. '.pdf'
    local forward_args = ' --synctex-forward '
        .. vim.fn.line('.')
        .. ':'
        .. vim.fn.col('.')
        .. ':'
        .. tex_file
        .. ' '
        .. pdf_file
    -- FIXME: How can we fork here?
    vim.fn.jobstart('zathura ' .. forward_args)
end

-- File Editing
local file_edit = function(extension)
    local base_file = vim.fn.fnamemodify(vim.b.vimtex.tex, ':p:r')
    local split = 'split '
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd(split .. base_file .. '.' .. extension)
end

-- Miscellaneous
local delete_aux_files = function()
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
    local files = scan.scan_dir(vim.fn.expand('%:p:h'))
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

-- Mappings
u.keymap('n', '<F7>', compile_latex, { buffer = true })
u.keymap('i', '<F7>', compile_latex, { buffer = true })
u.keymap('n', '<Leader>vp', view_pdf, { buffer = true })
u.keymap('n', '<Leader>sl', forward_search, { buffer = true })
u.keymap('n', '<Leader>da', delete_aux_files, { buffer = true })
u.keymap('n', '<Leader>eb', function()
    file_edit('bib')
end, { buffer = true })

-- Vimtex maps (for some reason we need to set them here instead of using an autocmd)
local vimtex_maps = { buffer = true, remap = true }
u.keymap('n', '<Leader>to', '<plug>(vimtex-toc-open)', vimtex_maps)
u.keymap('n', '<Leader>ce', '<plug>(vimtex-env-change)', vimtex_maps)
u.keymap('n', '<Leader>ts', '<plug>(vimtex-env-toggle-star)', vimtex_maps)
u.keymap('n', '<Leader>td', '<plug>(vimtex-delim-toggle-modifier)', vimtex_maps)
