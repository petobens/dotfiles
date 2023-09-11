local fn = vim.fn
local cmd = vim.cmd

local udfs = {}

function udfs.mk_non_dir(directory)
    local dir = directory or fn.expand('%:p:h')
    if fn.isdirectory(dir) == 0 then
        fn.mkdir(dir, 'p')
    end
end

function udfs.session_name()
    local session_dir = vim.env.CACHE .. '/tmp/session/'
    udfs.mk_non_dir(session_dir)
    local session_file = 'vim_session'
    if vim.env.TMUX ~= nil then
        local tmux_session = fn.trim(fn.system("tmux display-message -p '#S'"))
        session_file = session_file .. '_' .. tmux_session
    end
    return (session_dir .. session_file .. '.vim')
end

function udfs.diff_file_split()
    local save_pwd = fn.getcwd()
    cmd('lcd %:p:h')
    local win_id = fn.win_getid()
    vim.ui.input(
        { prompt = 'Input file for diffing: ', completion = 'file' },
        function(other_file)
            if not other_file or other_file == '' then
                return
            else
                local diffcmd = 'diffsplit '
                if fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
                    diffcmd = 'vertical ' .. diffcmd
                end
                cmd(diffcmd .. other_file)
            end
            fn.win_gotoid(win_id)
            cmd('normal gg]h') -- move to first hunk
        end
    )
    cmd('lcd ' .. save_pwd)
end

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
