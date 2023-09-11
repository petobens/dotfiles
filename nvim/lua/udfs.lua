local fn = vim.fn
local cmd = vim.cmd

local udfs = {}

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
