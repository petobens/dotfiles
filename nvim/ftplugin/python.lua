local builtin = require('telescope.builtin')
local overseer = require('overseer')
local u = require('utils')
local utils = require('telescope.utils')

-- Options and variable
vim.opt_local.textwidth = 88
vim.opt_local.commentstring = '#%s'
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
_G.OverseerConfig.python_errorformat = ''
    -- See https://github.com/python-mode/python-mode/blob/149ccf7c5be0753f5e9872c023ab2eeec3442105/autoload/pymode/run.vim#L4
    .. [[%E\ \ File\ \"%f\"\\\,\ line\ %l\\\,%m%\\C,]]
    .. [[%E\ \ File\ \"%f\"\\\,\ line\ %l%\\C,]]
    .. [[%C%p^,]]
    .. [[%-C\ \ %.%#,]]
    .. [[%-C\ \ \ \ %.%#,]]
    .. [[%Z%\\@=%m,]]
    .. [[%+GTraceback%.%#,]]
    .. [[%+GDuring\ handling%.%#,]]
    .. [[%+GThe\ above\ exception%.%#,]]
    .. [[%-G[Process exited%.%#,]]
    .. [[%f:%l:\ %.%#%tarning:%m,]]

-- Running
local function _parse_qf(task_metadata, cwd, active_window_id)
    local pdb = false

    local current_qf = vim.fn.getqflist()
    local new_qf = {}
    for _, v in pairs(current_qf) do
        if v.valid > 0 or v.text ~= '' then
            table.insert(new_qf, v)
            if string.match(v.text, 'bdb.BdbQuit') then
                pdb = true
            end
        end
    end

    if task_metadata and task_metadata.name == 'run_precommit' then
        -- Fix file paths
        for _, v in pairs(new_qf) do
            local fn = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(v.bufnr), ':p:.')
            for _, i in ipairs(task_metadata.project_files) do
                if string.match(i, fn) then
                    vim.cmd('badd ' .. i)
                    v.bufnr = vim.fn.bufnr(i)
                    break
                end
            end
        end
        vim.cmd('lcd ' .. cwd)
    end

    if next(new_qf) ~= nil then
        vim.fn.setqflist({}, ' ', { items = new_qf, title = task_metadata.run_cmd })
        if not pdb then
            vim.cmd('copen')
        end
        vim.fn.win_gotoid(active_window_id)
    end
end

local function run_overseer(task_name)
    local cwd = vim.fn.getcwd()
    local current_win_id = vim.fn.win_getid()
    vim.cmd('silent noautocmd update')

    if task_name == 'run_precommit' then
        vim.cmd('lcd %:p:h')
    end

    overseer.run_template({ name = string.format('%s', task_name) }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            task.metadata.name = task_name
            _parse_qf(task.metadata, cwd, current_win_id)
        end)
    end)

    if vim.api.nvim_get_mode()['mode'] == 'i' then
        vim.cmd.stopinsert()
    end
end

local function run_toggleterm(post_mortem_mode)
    post_mortem_mode = post_mortem_mode or false

    vim.cmd('silent noautocmd update')

    local cmd = 'python'
    if post_mortem_mode then
        cmd = cmd .. ' -m pdb -cc'
    end

    -- If we have an ipython terminal open don't run `python` cmd but rather `run`
    local ttt = require('toggleterm.terminal')
    local term_info = ttt.get(1)
    if term_info ~= nil and term_info.cmd ~= nil then
        if term_info.cmd == 'ipython' then
            cmd = '\\%run'
        end
    end

    vim.cmd(
        string.format(
            'TermExec cmd="%s %s"',
            cmd,
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        )
    )
end

local function run_ipython(mode)
    vim.cmd('silent noautocmd update')
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')

    local ttt = require('toggleterm.terminal')
    local term_info = ttt.get(1)
    local is_open = term_info ~= nil and term_info:is_open() or false
    if not is_open then
        local ipython = ttt.Terminal:new({
            cmd = 'ipython',
            hidden = false,
        })
        ipython:toggle()
        vim.cmd('wincmd p')
        vim.cmd('stopinsert')
    else
        if term_info ~= nil and term_info.cmd ~= 'ipython' then
            -- Switch to an ipython console if we are not already in one
            vim.cmd('TermExec cmd="ipython"')
            term_info.cmd = 'ipython'
        end
    end

    if mode == 'open' then
        return
    elseif mode == 'module' then
        vim.cmd(string.format('TermExec cmd="\\%%run %s"', fname))
    elseif mode == 'line' then
        vim.cmd('ToggleTermSendCurrentLine')
    elseif mode == 'selection' then
        vim.cmd('normal ') -- leave visual mode to set <,> marks
        vim.cmd('ToggleTermSendVisualLines')
    elseif mode == 'reset' then
        vim.cmd('TermExec cmd="\\%reset -f"')
    end
end

local function run_tmux_pane(debug_mode)
    if vim.env.TMUX == nil then
        return
    end

    local python_cmd = 'python'
    debug_mode = debug_mode or false
    if debug_mode then
        python_cmd = python_cmd .. ' -m pdb -cc'
    end

    local cwd = utils.buffer_dir()
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
    local sh_cmd = '"' .. python_cmd .. ' ' .. fname .. [[; read -p ''"]]
    vim.cmd('silent! !tmux new-window -c ' .. cwd .. ' -n ' .. fname .. ' ' .. sh_cmd)

    if vim.api.nvim_get_mode()['mode'] == 'i' then
        vim.cmd.stopinsert()
    end
end

local function tmux2qf(cmd_opt)
    local tmux_win_nr = cmd_opt.args
    local content = vim.fn.system('tmux capture-pane -p -t ' .. tmux_win_nr)
    vim.fn.setqflist({}, ' ', {
        lines = vim.split(content, '\n'),
        efm = _G.OverseerConfig.python_errorformat,
    })
    _parse_qf(
        { run_cmd = 'Tmux Window: ' .. tmux_win_nr },
        vim.fn.getcwd(),
        vim.fn.win_getid()
    )
end
vim.api.nvim_create_user_command('Tmux2Qf', tmux2qf, { nargs = 1 })

-- Debugging
local function add_breakpoint()
    local save_cursor = vim.fn.getcurpos()
    local current_line = vim.fn.line('.')
    local breakpoint_line = current_line - 1
    local indent_length = vim.fn.match(vim.fn.getline(current_line), '\\w')
    local bp_statement = string.rep(' ', indent_length) .. 'breakpoint()'
    vim.fn.append(breakpoint_line, bp_statement)
    vim.cmd('silent noautocmd update')
    vim.fn.setpos('.', save_cursor)
end

local function remove_breakpoints()
    local save_cursor = vim.fn.getcurpos()
    vim.cmd('g/breakpoint()/d')
    vim.cmd('silent noautocmd update')
    vim.fn.setpos('.', save_cursor)
end

local function list_breakpoints(local_buffer)
    local opts = {
        use_regex = true,
        search = 'breakpoint()',
    }
    if local_buffer == true then
        local buf_name = vim.api.nvim_buf_get_name(0)
        opts = vim.tbl_extend('keep', opts, {
            results_title = buf_name,
            search_dirs = { buf_name },
        })
    else
        local buffer_dir = utils.buffer_dir()
        if next(_G.Venv.active_venv) ~= nil then
            buffer_dir = _G.Venv.active_venv.project_root
        end
        opts = vim.tbl_extend('keep', opts, {
            cwd = buffer_dir,
            results_title = buffer_dir,
        })
    end
    builtin.grep_string(opts)
end

-- Mappings
---- Background running
u.keymap({ 'n', 'i' }, '<F7>', function()
    run_overseer('run_python')
end, { buffer = true })
u.keymap({ 'n', 'i' }, '<F5>', run_tmux_pane, { buffer = true })
u.keymap({ 'n', 'i' }, '<F6>', function()
    run_tmux_pane(true)
end, { buffer = true })
---- Interactive running
u.keymap('n', '<Leader>rf', run_toggleterm, { buffer = true })
u.keymap('n', '<Leader>rp', function()
    run_toggleterm(true)
end, { buffer = true })
u.keymap('n', '<Leader>oi', function()
    run_ipython('open')
end, { buffer = true })
u.keymap('n', '<Leader>ri', function()
    run_ipython('module')
end, { buffer = true })
u.keymap('n', '<Leader>rl', function()
    run_ipython('line')
end, { buffer = true })
u.keymap('v', '<Leader>ri', function()
    run_ipython('selection')
end, { buffer = true })
u.keymap('n', '<Leader>tr', function()
    run_ipython('reset')
end, { buffer = true })
---- Debugging
u.keymap('n', '<Leader>bp', add_breakpoint, { buffer = true })
u.keymap('n', '<Leader>rb', remove_breakpoints, { buffer = true })
u.keymap('n', '<Leader>lb', function()
    list_breakpoints(true)
end, { buffer = true })
u.keymap('n', '<Leader>lB', function()
    list_breakpoints(false)
end, { buffer = true })
u.keymap('n', '<Leader>lt', ':Tmux2Qf ', { silent = false })
-- Pre-commit
u.keymap('n', '<Leader>rh', function()
    run_overseer('run_precommit')
end, { buffer = true })

-- Autocommand mappings
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vim.api.nvim_create_augroup('qf_bp', { clear = true }),
    pattern = { 'qf' },
    callback = function()
        u.keymap('n', '<Leader>rB', function()
            vim.cmd([[cdo g/breakpoint()/d|silent noautocmd update]])
            vim.cmd('cclose')
        end, { buffer = true })
    end,
})
