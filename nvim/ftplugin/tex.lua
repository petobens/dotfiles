local overseer = require('overseer')
local u = require('utils')

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

-- Mappings
u.keymap('n', '<F7>', compile_latex, { buffer = true })
u.keymap('i', '<F7>', compile_latex, { buffer = true })
