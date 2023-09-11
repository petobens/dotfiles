local fn = vim.fn
local cmd = vim.cmd

local udfs = {}

function udfs.open_links(mode)
    local url
    if mode == 'v' then
        url = string.sub(fn.getline("'<"), fn.getpos("'<")[2] + 2, fn.getpos("'>")[3])
    else
        url = vim.fn.matchstr(
            vim.fn.getline('.'),
            [[\(http\|www\.\)[^ ]:\?[[:alnum:]%\/_#.-]*]]
        )
    end
    url = fn.escape(url, '#!?&;|%')
    cmd('silent! !xdg-open ' .. url)
    cmd('redraw!')
end

function udfs.visual_search(direction)
    local tmp_register = fn.getreg('s')
    cmd('normal! gv"sy')
    fn.setreg(
        '/',
        '\\V'
            .. fn.substitute(
                fn.escape(fn.getreg('s'), direction .. '\\'),
                '\\n',
                '\\\\n',
                'g'
            )
    )
    fn.setreg('s', tmp_register)
end

_G.udfs = udfs

return udfs
