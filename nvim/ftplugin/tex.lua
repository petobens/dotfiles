local overseer = require('overseer')
local u = require('utils')

-- Options
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.iskeyword = '@,48-57,_,192-255,:'
vim.opt_local.indentkeys = '!^F,o,O,0=\\item'
vim.opt.comments = vim.opt.comments + { 'b:\\item' }

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

local _parse_logfile = function(filename)
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
    if next(items) ~= nil then
        vim.cmd('copen')
    end
end

local compile_latex = function()
    vim.cmd('silent noautocmd update')
    overseer.run_template({ name = 'run_arara' }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            local log_file = vim.fn.fnamemodify(task.metadata.filename, ':p:r') .. '.log'
            _parse_logfile(log_file)
        end)
    end)
end

-- Viewing
local view_pdf = function()
    local tex_file = vim.fn.expand('%:p')
    local pdf_file = vim.fn.fnamemodify(tex_file, ':p:r') .. '.pdf'
    vim.cmd('silent! !tmux new-window -d zathura --fork ' .. pdf_file)
end

local forward_search = function()
    local tex_file = vim.fn.expand('%:p')
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
    local cmd = 'silent! !tmux new-window -d zathura ' .. forward_args
    vim.cmd(cmd)
end

-- File Editing
local file_edit = function(extension)
    local base_file = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':p:r')
    local split = 'split '
    ---@diagnostic disable-next-line: undefined-field
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd(split .. base_file .. '.' .. extension)
end

-- Mappings
u.keymap('n', '<F7>', compile_latex, { buffer = true })
u.keymap('i', '<F7>', compile_latex, { buffer = true })
u.keymap('n', '<Leader>vp', view_pdf, { buffer = true })
u.keymap('n', '<Leader>sl', forward_search, { buffer = true })
u.keymap('n', '<Leader>eb', function()
    file_edit('bib')
end, { buffer = true })
