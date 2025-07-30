local builtin = require('telescope.builtin')
local overseer = require('overseer')
local u = require('utils')

-- Options and variable
vim.opt_local.textwidth = 88
vim.opt_local.commentstring = '#%s'
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldtext = ''
_G.OverseerConfig.python_errorformat = ''
    -- luacheck:ignore 631
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

-- Helpers
local function _project_root()
    local root = vim.fs.root(0, 'pyproject.toml')
    if not root or root == '' then
        return vim.uv.cwd()
    end
    return root
end

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
        vim.cmd.lcd({ args = { cwd } })
    end

    if next(new_qf) ~= nil then
        vim.fn.setqflist({}, ' ', { items = new_qf, title = task_metadata.run_cmd })
        if not pdb then
            vim.cmd.copen()
        end
        vim.api.nvim_set_current_win(active_window_id)
    end
end

local function run_overseer(task_name)
    local cwd = vim.uv.cwd()
    local current_win_id = vim.api.nvim_get_current_win()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })

    if task_name == 'run_precommit' then
        vim.cmd.lcd({ args = { vim.fs.dirname(vim.api.nvim_buf_get_name(0)) } })
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

    vim.cmd.update({ mods = { silent = true, noautocmd = true } })

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

    vim.cmd(string.format('TermExec cmd="%s %s"', cmd, vim.api.nvim_buf_get_name(0)))
end

local function run_ipython(mode)
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    local fname = vim.api.nvim_buf_get_name(0)

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
    elseif mode == 'carriage' then
        local current_win_id = vim.api.nvim_get_current_win()
        vim.fn.win_gotoid(vim.fn.bufwinid('ipython'))
        vim.api.nvim_input('<CR>')
        vim.defer_fn(function()
            vim.api.nvim_set_current_win(current_win_id)
        end, 100)
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

    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local fname = vim.fs.basename(vim.api.nvim_buf_get_name(0))
    local sh_cmd = '"' .. python_cmd .. ' ' .. fname .. [[; read -p ''"]]
    vim.cmd({
        cmd = '!',
        args = { 'tmux', 'new-window', '-c', cwd, '-n', fname, sh_cmd },
        mods = { silent = true },
    })

    if vim.api.nvim_get_mode()['mode'] == 'i' then
        vim.cmd.stopinsert()
    end
end

local function tmux2qf(cmd_opt)
    local tmux_win_nr = cmd_opt.args
    local result = vim.system(
        { 'tmux', 'capture-pane', '-p', '-t', tmux_win_nr },
        { text = true }
    )
        :wait()
    vim.fn.setqflist({}, ' ', {
        lines = vim.split(result.stdout or '', '\n', { plain = true }),
        efm = _G.OverseerConfig.python_errorformat,
    })
    _parse_qf(
        { run_cmd = 'Tmux Window: ' .. tmux_win_nr },
        vim.uv.cwd(),
        vim.api.nvim_get_current_win()
    )
end
vim.api.nvim_create_user_command('Tmux2Qf', tmux2qf, { nargs = 1 })

-- Debugging
local function add_breakpoint()
    local save_cursor = vim.api.nvim_win_get_cursor(0)
    local current_line = save_cursor[1]
    local breakpoint_line = current_line - 1
    local indent_length = vim.fn.match(vim.fn.getline(current_line), '\\w')
    local bp_statement = string.rep(' ', indent_length) .. 'breakpoint()'
    vim.api.nvim_buf_set_lines(
        0,
        breakpoint_line,
        breakpoint_line,
        false,
        { bp_statement }
    )
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.api.nvim_win_set_cursor(0, save_cursor)
end

local function remove_breakpoints()
    local save_cursor = vim.api.nvim_win_get_cursor(0)
    vim.cmd('g/breakpoint()/d')
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.api.nvim_win_set_cursor(0, save_cursor)
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
        local buffer_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
        if next(_G.PyVenv.active_venv) ~= nil then
            buffer_dir = _G.PyVenv.active_venv.project_root
        end
        opts = vim.tbl_extend('keep', opts, {
            cwd = buffer_dir,
            results_title = buffer_dir,
        })
    end
    builtin.grep_string(opts)
end

-- Virtual Envs
local function get_venv_info(venv, project_root)
    if venv and venv ~= '' then
        return { path = venv, manager = nil }
    end
    -- Prefer uv over poetry
    local uv_venv = vim.fs.joinpath(project_root, '.venv')
    if vim.uv.fs_stat(uv_venv) and vim.uv.fs_stat(uv_venv).type == 'directory' then
        return { path = uv_venv, manager = 'uv' }
    end
    local result = vim.system({ 'poetry', 'env', 'info', '--path' }, { text = true })
        :wait()
    local poetry_venv = vim.trim(result.stdout or '')
    if poetry_venv ~= '' and result.code == 0 then
        return { path = poetry_venv, manager = 'poetry' }
    end
    return nil
end

local function set_lsp_path(path)
    -- Needed to jump to proper docs/definitions
    -- From https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/basedpyright.lua#L28
    local client = vim.lsp.get_clients({ name = 'basedpyright' })[1]
    if client then
        client.settings.python = vim.tbl_deep_extend(
            'force',
            client.settings.python or {},
            { pythonPath = path }
        )
        client.notify('workspace/didChangeConfiguration', { settings = nil })
    end
end

function _G.PyVenv.activate(venv)
    if vim.b.pyvenv and vim.b.pyvenv == _G.PyVenv.active_venv.path then
        return
    else
        if
            next(_G.PyVenv.active_venv) ~= nil
            and vim.tbl_contains(
                _G.PyVenv.active_venv.project_files,
                vim.api.nvim_buf_get_name(0)
            )
        then
            -- Current file belongs to the project of the active env then simply
            -- set the buffer cache variable since we can reuse the existing venv
            vim.b.pyvenv = _G.PyVenv.active_venv.path
            return
        else
            _G.PyVenv.deactivate()
        end
    end

    -- Save working dir and cd to window cwd (lcd) to ensure system call works
    local lwd = vim.uv.cwd()
    vim.cmd.lcd({ args = { lwd } })

    -- If there is no active venv look for one (but just once)
    if vim.b.pyvenv == nil then
        local project_root = _project_root()
        local venv_info = get_venv_info(venv, project_root)
        if venv_info then
            vim.b.pyvenv = venv_info.path
            local py_files = vim.fs.find(function(name, path)
                return name:match('.*%.py$')
                    and not vim.startswith(path, project_root .. '/.venv/')
            end, {
                limit = math.huge,
                type = 'file',
                path = project_root,
            })
            local result = vim.system(
                { venv_info.manager, 'run', 'python', '--version' },
                { text = true }
            ):wait()
            local py_version = vim.trim(result.stdout or ''):match('%d+.%d+.%d+')
            _G.PyVenv.active_venv = {
                package_manager = venv_info.manager,
                path = venv_info.path,
                project_files = py_files,
                project_root = project_root,
                python_version = py_version,
            }
        else
            vim.b.pyvenv = 'none'
        end
    end

    -- Actually activate the venv if it was found
    if vim.b.pyvenv ~= 'none' then
        vim.env.PATH = string.format('%s/bin:%s', vim.b.pyvenv, vim.env.PATH)
        vim.env.VIRTUAL_ENV = vim.b.pyvenv
        local lsp_path = vim.b.pyvenv .. '/bin/python'
        vim.defer_fn(function()
            set_lsp_path(lsp_path)
        end, 100)
    end
    vim.cmd.lcd({ args = { lwd } })
end

function _G.PyVenv.deactivate()
    if
        _G.PyVenv.active_venv.path
        and string.find(vim.env.PATH, _G.PyVenv.active_venv.path, 1, true)
    then
        local venv_path =
            string.gsub(_G.PyVenv.active_venv.path .. '/bin:', '([^%w])', '%%%1') -- escaped
        local path = string.gsub(vim.env.PATH, venv_path, '')
        vim.env.PATH = path
    end
    vim.env.VIRTUAL_ENV = nil
    vim.b.pyvenv = nil
    _G.PyVenv.active_venv = {}
    set_lsp_path(vim.g.python3_host_prog)
end

-- Sphinx(docs)
local function run_sphinx_build()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    overseer.run_template({ name = 'run_sphinx_build' }, function()
        vim.cmd('cclose')
    end)
end

local function clean_sphinx_build()
    local on_exit = function(obj)
        if obj.code == 0 then
            vim.print('Cleaning sphinx html build... done!')
        else
            vim.print(obj.stderr, vim.log.levels.ERROR)
        end
    end

    vim.notify('Cleaning sphinx html build...')
    vim.system(
        { _G.PyVenv.active_venv.package_manager, 'run', 'make', 'clean' },
        { cwd = vim.fs.joinpath(_project_root(), 'docs'), text = true },
        on_exit
    )
end

local function view_sphinx_docs(opts)
    local project_root = _project_root() .. '/'
    local html_file

    opts = opts or {}
    if opts.index then
        html_file = project_root .. 'docs/build/html/index.html'
    else
        local docs_dir = project_root .. 'docs/build/html/api-reference/_autosummary/'
        local root_escaped = string.gsub(project_root, '([^%w])', '%%%1')
        local current_file = vim.fn.expand('%:p:r')
        html_file = docs_dir
            .. current_file:gsub(root_escaped, '', 1):gsub('/', '.')
            .. '.html'
    end
    vim.ui.open(html_file)
end

-- Fast editing
local function edit_test_file()
    local tests_dir = vim.fs.joinpath(_project_root(), 'tests')
    local test_file = vim.fs.find(
        { 'test_' .. vim.fs.basename(vim.api.nvim_buf_get_name(0)) },
        { limit = math.huge, type = 'file', path = tests_dir }
    )
    if next(test_file) then
        u.split_open(test_file[1])
    else
        vim.cmd(':Telescope find_files cwd=' .. tests_dir)
    end
end

local function edit_project_todo()
    local notes_dir = vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'notes')
    local todo_file = vim.fs.find(
        { 'todos_' .. vim.fs.basename(_project_root()) .. '.md' },
        { limit = math.huge, type = 'file', path = notes_dir }
    )
    if next(todo_file) then
        u.split_open(todo_file[1])
    else
        vim.cmd(':Telescope find_files cwd=' .. notes_dir)
    end
end

-- Mappings
---- Background running
vim.keymap.set({ 'n', 'i' }, '<F7>', function()
    run_overseer('run_python')
end, { buffer = true })
vim.keymap.set({ 'n', 'i' }, '<F5>', run_tmux_pane, { buffer = true })
vim.keymap.set({ 'n', 'i' }, '<F6>', function()
    run_tmux_pane(true)
end, { buffer = true })
---- Interactive running
vim.keymap.set('n', '<Leader>rf', run_toggleterm, { buffer = true })
vim.keymap.set('n', '<Leader>rp', function()
    run_toggleterm(true)
end, { buffer = true })
vim.keymap.set('n', '<Leader>oi', function()
    run_ipython('open')
end, { buffer = true })
vim.keymap.set('n', '<Leader>ri', function()
    run_ipython('module')
end, { buffer = true })
vim.keymap.set('n', '<Leader>rl', function()
    run_ipython('line')
end, { buffer = true })
vim.keymap.set('v', '<Leader>ri', function()
    run_ipython('selection')
end, { buffer = true })
vim.keymap.set('n', '<Leader>tr', function()
    run_ipython('reset')
end, { buffer = true })
vim.keymap.set('n', '<Leader>tx', function()
    run_ipython('carriage')
end, { buffer = true })
---- Debugging
vim.keymap.set('n', '<Leader>bp', add_breakpoint, { buffer = true })
vim.keymap.set('n', '<Leader>rb', remove_breakpoints, { buffer = true })
vim.keymap.set('n', '<Leader>lb', function()
    list_breakpoints(true)
end, { buffer = true })
vim.keymap.set('n', '<Leader>lB', function()
    list_breakpoints(false)
end, { buffer = true })
vim.keymap.set('n', '<Leader>lt', ':Tmux2Qf ', { silent = false })
---- Pre-commit
vim.keymap.set('n', '<Leader>rh', function()
    run_overseer('run_precommit')
end, { buffer = true })
---- Virtual Envs
vim.keymap.set('n', '<Leader>va', function()
    _G.PyVenv.activate()
end, { buffer = true })
vim.keymap.set('n', '<Leader>vd', function()
    _G.PyVenv.deactivate()
end, { buffer = true })
vim.keymap.set('n', '<Leader>vl', function()
    _G.TelescopeConfig.py_venvs({ project_root = _project_root() })
end, { buffer = true })
vim.keymap.set('n', '<Leader>ve', function()
    vim.print(_G.PyVenv.active_venv)
end, { buffer = true })
---- Sphinx (docs)
vim.keymap.set('n', '<Leader>bh', run_sphinx_build, { buffer = true }) -- build html
vim.keymap.set('n', '<Leader>da', clean_sphinx_build, { buffer = true }) -- delete aux
vim.keymap.set('n', '<Leader>od', view_sphinx_docs, { buffer = true }) -- open docs
vim.keymap.set('n', '<Leader>vi', function()
    view_sphinx_docs({ index = true })
end, { buffer = true })
---- Editing
vim.keymap.set('n', '<Leader>etf', edit_test_file, { buffer = true })
vim.keymap.set('n', '<Leader>etp', edit_project_todo, { buffer = true })

-- Autocommand mappings
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = vim.api.nvim_create_augroup('qf_bp', { clear = true }),
    pattern = { 'qf' },
    callback = function(e)
        vim.keymap.set('n', '<Leader>rB', function()
            vim.cmd([[cdo g/breakpoint()/d|silent noautocmd update]])
            vim.cmd('cclose')
        end, { buffer = e.buf })
    end,
})
