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


_G.udfs = udfs

return udfs
