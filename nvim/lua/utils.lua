local M = {}

M.icons = {
    -- Running
    error = '',
    hint = '',
    info = '',
    running = '󰜎',
    warning = '',
    -- Folding
    fold_close = '',
    fold_open = '',
}

-- Files
function M.split_open(file)
    local split = 'split'
    if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit'
    end
    vim.cmd[split](file)
end

function M.mk_non_dir(directory)
    local dir = directory or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local stat = vim.uv.fs_stat(dir)
    if stat == nil or stat.type ~= 'directory' then
        vim.fn.mkdir(dir, 'p')
    end
end

-- Vim UI
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
                session_file = string.format('%s_%s', session_file, tmux_session)
            end
        end
    end
    return vim.fs.joinpath(session_dir, string.format('%s.vim', session_file))
end

function M.get_selection()
    local mode = vim.fn.mode()
    if mode:match('^[vV\22]') then
        local type_map = { v = 'v', V = 'V', ['\22'] = 'b' }
        local vtype = type_map[mode] or 'v'
        local start_pos = vim.fn.getpos('v')
        local end_pos = vim.fn.getpos('.')
        local region = vim.fn.getregion(start_pos, end_pos, { type = vtype })
        return table.concat(region, '\n')
    end
    return vim.fn.expand('<cword>')
end

function M.quit_return()
    vim.cmd.wincmd('p')
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd.wincmd('p')
    vim.cmd.bdelete()
    if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_set_current_win(win_id)
    end
end

-- Online check
local last_online_check, online_status
local online_cache_timeout = 30
function M.is_online()
    local now = os.time()
    if last_online_check and (now - last_online_check < online_cache_timeout) then
        return online_status
    end

    local res = vim.system({
        'curl',
        '-fsS',
        '--max-time',
        '1',
        'https://clients3.google.com/generate_204',
    }, { text = true, timeout = 1000 }):wait()
    online_status = (res.code == 0)
    last_online_check = now
    return online_status
end

-- Pass
local pass_cache = {}
function M.resolve_pass(path)
    vim.validate('path', path, 'string')

    local normalized_path = vim.trim(path)
    if normalized_path == '' then
        return nil, 'pass path must not be empty'
    end

    if pass_cache[normalized_path] then
        return pass_cache[normalized_path]
    end

    local result = vim.system({ 'pass', 'show', normalized_path }, { text = true }):wait()
    if result.code ~= 0 then
        return nil,
            vim.trim(result.stderr or '') ~= '' and vim.trim(result.stderr)
                or ('Could not read pass entry: %s'):format(normalized_path)
    end

    local value = vim.trim(result.stdout or '')
    if value == '' then
        return nil, ('Pass entry is empty: %s'):format(normalized_path)
    end

    pass_cache[normalized_path] = value
    return value
end

return M
