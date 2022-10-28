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
local LATEX_EFM = [[%-P**%f,]]
    .. [[%-P**\"%f\",]]
    .. [[%E!\ LaTeX\ %trror:\ %m,]]
    .. [[%E%f:%l:\ %m,]]
    .. [[%E!\ %m,]]
    .. [[%Z<argument>\ %m,]]
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
    .. [[%-G%.%#refsection%.%#,]] -- ignore refsection and float warnings
    .. [[%-G%.%#contains\ only\ floats%.%#,]]
    .. [[%-G%.%#,]]

local parse_logfile = function(filename)
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
    overseer.run_template({ name = 'Run Arara' }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            local log_file = vim.fn.fnamemodify(task.metadata.filename, ':p:r') .. '.log'
            parse_logfile(log_file)
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

-- Mappings
u.keymap('n', '<F7>', compile_latex, { buffer = true })
u.keymap('i', '<F7>', compile_latex, { buffer = true })
u.keymap('n', '<Leader>vp', view_pdf, { buffer = true })
u.keymap('n', '<Leader>sl', forward_search, { buffer = true })
