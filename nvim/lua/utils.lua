local M = {}

local ftoptions_group = vim.api.nvim_create_augroup('FtOptions', {})
function M.set_ft_option(ft, vim_cmd)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        group = ftoptions_group,
        command = vim_cmd,
    })
end

function M.split_open(file)
    local split = 'split '
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd(split .. file)
end

function M.mk_non_dir(directory)
    local dir = directory or vim.fn.expand('%:p:h')
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
    end
end

function M.vim_session_file()
    local session_dir = vim.env.CACHE .. '/tmp/session/'
    M.mk_non_dir(session_dir)
    local session_file = 'vim_session'
    if vim.env.TMUX ~= nil then
        local result = vim.system(
            { 'tmux', 'display-message', '-p', '#S' },
            { text = true }
        )
            :wait()
        local tmux_session = vim.trim(result.stdout or '')
        session_file = session_file .. '_' .. tmux_session
    end
    return session_dir .. session_file .. '.vim'
end

function M.border(hl_name)
    return {
        { '╭', hl_name },
        { '─', hl_name },
        { '╮', hl_name },
        { '│', hl_name },
        { '╯', hl_name },
        { '─', hl_name },
        { '╰', hl_name },
        { '│', hl_name },
    }
end

function M.get_selection()
    local text
    if vim.fn.mode() == 'v' then
        vim.cmd('noautocmd normal! "vy"')
        text = vim.fn.getreg('v')
        vim.fn.setreg('v', {})
        text = string.gsub(text, '\n', '')
    else
        text = vim.fn.expand('<cWORD>')
    end
    return text
end

function M.quit_return()
    vim.cmd('wincmd p')
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd('wincmd p')
    vim.cmd('bdelete')
    vim.fn.win_gotoid(win_id)
end

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
