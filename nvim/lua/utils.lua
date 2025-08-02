local M = {}

M.icons = {
    -- Running
    error = '',
    warning = '',
    info = '',
    hint = '',
    running = '󰜎',
    -- Folding
    fold_open = '',
    fold_close = '',
}

function M.split_open(file)
    local split = 'split '
    if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd({ cmd = split, args = { file } })
end

function M.mk_non_dir(directory)
    local dir = directory or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local stat = vim.uv.fs_stat(dir)
    if stat == nil or stat.type ~= 'directory' then
        vim.fn.mkdir(dir, 'p')
    end
end

function M.vim_session_file()
    local session_dir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'session')
    M.mk_non_dir(session_dir)
    local session_file = 'vim_session'

    if vim.env.TMUX and vim.env.TMUX ~= '' then
        local result = vim.system(
            { 'tmux', 'display-message', '-p', '#S' },
            { text = true }
        )
            :wait()
        if result.code == 0 then
            local tmux_session = vim.trim(result.stdout or '')
            if tmux_session ~= '' then
                session_file = session_file .. '_' .. tmux_session
            end
        end
    end
    return vim.fs.joinpath(session_dir, session_file .. '.vim')
end

function M.get_selection()
    local mode = vim.api.nvim_get_mode().mode
    if mode:match('^v') then
        local bufnr = 0
        local start_pos = vim.api.nvim_buf_get_mark(bufnr, '<')
        local end_pos = vim.api.nvim_buf_get_mark(bufnr, '>')
        local lines = vim.api.nvim_buf_get_text(
            bufnr,
            start_pos[1] - 1,
            start_pos[2],
            end_pos[1] - 1,
            end_pos[2] + 1,
            {}
        )
        return table.concat(lines, '\n')
    else
        return vim.fn.expand('<cWORD>')
    end
end

function M.quit_return()
    vim.cmd.wincmd({ args = { 'p' } })
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd.wincmd({ args = { 'p' } })
    vim.cmd.bdelete()
    if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_set_current_win(win_id)
    end
end

local last_online_check, online_status
local online_cache_timeout = 30
function M.is_online()
    local now = os.time()
    if last_online_check and (now - last_online_check < online_cache_timeout) then
        return online_status
    end
    online_status = vim.system({ 'ping', '-c', '1', '8.8.8.8' }, { timeout = 1000 })
        :wait().code == 0
    last_online_check = now
    return online_status
end

return M
