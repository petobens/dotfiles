local udfs = {}

function udfs.session_name()
    session_dir = vim.env.CACHE .. '/tmp/session/'
    vim.fn.mkdir(session_dir, 'p')
    session_file = 'vim_session'
    if vim.env.TMUX ~= nil then
        tmux_session = vim.fn.trim(vim.fn.system("tmux display-message -p '#S'"))
        session_file = session_file .. '_' .. tmux_session
    end
    return session_dir .. session_file .. '.vim'
end

function udfs.goto_file_insplit()
    wincmd = 'wincmd f'
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        wincmd = 'vertical ' .. wincmd
    end
    vim.cmd(wincmd)
end

function udfs.diff_file_split()
    save_pwd = vim.fn.getcwd()
    vim.cmd('lcd %:p:h')
    win_id = vim.fn.win_getid()
    other_file = vim.fn.input('Input file for diffing: ', '', 'file')
    if other_file == '' then
        return
    end
    diffcmd = 'diffsplit '
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
       diffcmd = 'vertical ' .. diffcmd
    end
    vim.cmd(diffcmd .. other_file)
    vim.fn.win_gotoid(win_id)
    vim.cmd('normal gg]c') -- move to first hunk
    vim.cmd('lcd ' .. save_pwd)
end


_G.udfs = udfs

return udfs
