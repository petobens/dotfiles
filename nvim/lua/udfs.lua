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

_G.udfs = udfs

return udfs
