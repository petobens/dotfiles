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

function udfs.goto_file_insplit()
    local wincmd = 'wincmd f'
    if fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        wincmd = 'vertical ' .. wincmd
    end
    cmd(wincmd)
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

function udfs.tmux_split_cmd(tmux_cmd, cwd_arg)
    if vim.env.TMUX == nil then
        return
    end
    local cwd = cwd_arg or fn.getcwd()
    cmd('silent! !tmux split-window -p 30 -c ' .. cwd .. ' ' .. tmux_cmd)
end

function udfs.highlight_word(n)
    cmd('normal! mz')
    cmd('normal! "zyiw')
    local mid = 86750 + n -- arbitrary match id
    cmd('silent! call matchdelete(' .. mid .. ')')
    local pat = '\\V\\<' .. fn.escape(fn.getreg('z'), '\\') .. '\\>'
    fn.matchadd('HlWord' .. n, pat, 1, mid)
    cmd('normal! `z')
end

function udfs.open_fold_from_start()
    local foldstart_linenr = fn.foldclosed('.')
    if foldstart_linenr == -1 then
        cmd('normal! l')
        return
    end
    cmd('normal! zo')
    cmd('normal! ' .. foldstart_linenr .. 'G^')
end

_G.udfs = udfs

return udfs
