local neotest = require('neotest')
local u = require('utils')

-- Helpers
local function set_output_window_layout(height)
    vim.cmd.wincmd('J')
    vim.cmd.resize(tostring(height or 15))
    vim.cmd.set('winfixheight')
end

local function is_qf_duplicate(entry, entries)
    for _, e in ipairs(entries) do
        if entry.bufnr == e.bufnr and entry.lnum == e.lnum and entry.text == e.text then
            return true
        end
    end
    return false
end

local function _parse_neotest_output(task, last_winid)
    -- Set the diagnostic qf
    local diagnostics = vim.diagnostic.get(task.bufnr)
    local qf_diagnostic = vim.diagnostic.toqflist(diagnostics)
    local diagnostic_entries = {}
    for _, v in pairs(qf_diagnostic) do
        table.insert(
            diagnostic_entries,
            { bufnr = v.bufnr, lnum = v.lnum, text = v.text }
        )
    end

    -- Create another qf from output but avoid repeating diagnostics entries
    local efm = { python = [[%E%f:%l:\ %m,%-G%.%#,]] }
    local has_stdout, pdb = false, false
    local lines = vim.api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, true)
    for _, v in ipairs(lines) do
        if task.ft == 'python' then
            if not has_stdout and v:find('Captured stdout call', 1, true) then
                has_stdout = true
            end
            if v:find('bdb.BdbQuit', 1, true) then
                pdb = true
            end
        end
    end

    vim.fn.setqflist({}, ' ', {
        lines = lines,
        efm = efm[task.ft],
    })

    local qf_output = {}
    for _, v in pairs(vim.fn.getqflist()) do
        if not is_qf_duplicate(v, diagnostic_entries) then
            table.insert(qf_output, v)
        end
    end

    -- If we have output then open it
    if has_stdout then
        require('overseer').run_action(task, 'open hsplit')
        vim.defer_fn(function()
            vim.cmd.stopinsert()
        end, 5)
        set_output_window_layout()
        vim.opt_local.winfixbuf = true
        vim.opt_local.modifiable = true
        vim.cmd.normal({ args = { 'kdGggG' }, bang = true, mods = { silent = true } })
        vim.opt_local.modifiable = false
        vim.keymap.set('n', 'q', function()
            local calling_winid = _G.LastWinId
            vim.cmd.close()
            pcall(vim.api.nvim_set_current_win, calling_winid)
        end, { buffer = true, desc = 'Close neotest output window and return' })
    end

    -- Combine both qf lists and open qf if needed
    local qf = vim.list_extend(qf_diagnostic, qf_output)
    if not vim.tbl_isempty(qf) then
        vim.fn.setqflist({}, ' ', { title = task.name, items = qf })
        if not pdb then
            vim.cmd.copen()
            vim.api.nvim_set_current_win(last_winid)
            if has_stdout then
                -- overseer run_action creates a new empty buffer so we delete it
                local buffers = vim.api.nvim_list_bufs()
                vim.api.nvim_buf_delete(buffers[#buffers], {})
            end
        else
            -- Reset qf and diagnostics
            vim.fn.setqflist({})
            vim.cmd.cclose()
            if diagnostics and diagnostics[1] then
                vim.defer_fn(function()
                    vim.diagnostic.reset(diagnostics[1].namespace, diagnostics[1].bufnr)
                end, 100)
            end
        end
    end
end

local function _neotest_overseer_subscribe(ft, bufnr)
    local overseer = require('overseer')
    local tasks = {}
    while vim.tbl_isempty(tasks) do
        vim.wait(100)
        tasks = overseer.list_tasks({ recent_first = true })
    end

    -- We record filetype and buffer number since we might call neotest.run from a
    -- terminal buffer when attaching to it
    local neotest_task = tasks[1]
    neotest_task.ft = ft
    neotest_task.bufnr = bufnr

    neotest_task:subscribe('on_complete', function()
        _parse_neotest_output(neotest_task, vim.api.nvim_get_current_win())
    end)
end

local function neotest_run(func, opts, subscribe)
    local ft = vim.bo.filetype
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.cmd.cclose()
    vim.api.nvim_set_current_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))

    -- Delete terminal (overseer output) buffers unless otherwise specified (i.e. when
    -- attaching)
    opts = opts or {}
    local delete = opts.delete ~= false
    opts.delete = nil
    if delete then
        for _, bufnum in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(bufnum)
            if vim.startswith(name, 'term://') then
                vim.api.nvim_buf_delete(bufnum, { force = true })
            end
        end
    end

    func(opts)

    local post = (subscribe == nil and true) or subscribe
    if post then
        _neotest_overseer_subscribe(ft, bufnr)
    end
end

-- Setup
neotest.setup({
    adapters = {
        require('neotest-python')({ args = { '--no-header', '-raP', '--tb=line' } }),
    },
    consumers = {
        overseer = require('neotest.consumers.overseer'),
    },
    discovery = {
        enabled = true,
    },
    diagnostic = {
        enabled = true,
    },
    status = {
        enabled = true,
        virtual_text = true,
        signs = false,
    },
    output = {
        enabled = true,
        open_on_run = false,
    },
    quickfix = {
        enabled = false,
    },
    summary = {
        follow = true,
        open = 'topleft vsplit | wincmd H | vertical resize 40',
        mappings = {
            attach = 'a',
            expand = { 'zo', 'zc' }, -- also collapse
            expand_all = 'zr',
            jumpto = { '<CR>', '<C-]>' },
            short = 'o', -- open with short output
            run = 'r',
            run_marked = 'R',
            stop = 's',
            mark = '<Space>',
            clear_marked = '<C-Space>',
            target = 't',
            clear_target = 'u',
        },
    },
    icons = {
        expanded = '',
        collapsed = '',
        child_prefix = '',
        child_indent = '  ',
        final_child_prefix = '',
        non_collapsible = '',
        passed = ' ',
        running = u.icons.running,
        failed = ' ',
        unknown = ' ',
        skipped = ' ',
        running_animated = vim.tbl_map(function(s)
            return s .. ' '
        end, {
            '⠋',
            '⠙',
            '⠹',
            '⠸',
            '⠼',
            '⠴',
            '⠦',
            '⠧',
            '⠇',
            '⠏',
        }),
    },
})

-- Autocmds options
vim.api.nvim_create_autocmd('FileType', {
    desc = 'Configure neotest output panel window',
    group = vim.api.nvim_create_augroup('NeotestConfig', {}),
    pattern = 'neotest-output-panel',
    callback = set_output_window_layout,
})

-- Mappings
vim.keymap.set('n', '<Leader>nn', function()
    neotest_run(neotest.run.run)
end, { desc = 'Run nearest test' })

vim.keymap.set('n', '<Leader>nl', function()
    neotest_run(neotest.run.run_last)
end, { desc = 'Run last test' })

vim.keymap.set('n', '<Leader>nf', function()
    neotest_run(neotest.run.run, { vim.api.nvim_buf_get_name(0) })
end, { desc = 'Run all tests in file' })

vim.keymap.set('n', '<Leader>ns', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '--cov')
    end
    neotest_run(neotest.run.run, { suite = true, extra_args = extra_args })
end, { desc = 'Run test suite' })

vim.keymap.set('n', '<Leader>nd', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '-x')
        table.insert(extra_args, '--pdb')
    end
    neotest_run(neotest.run.run, { extra_args = extra_args })
end, { desc = 'Run test with debugger' })

vim.keymap.set('n', '<Leader>na', function()
    neotest_run(neotest.run.attach, { delete = false })
    vim.keymap.set('n', 'q', function()
        vim.cmd.close()
    end, { buffer = true, desc = 'Close neotest attach window and return' })
    vim.cmd.stopinsert()
    set_output_window_layout()
    vim.cmd.startinsert()
end, { desc = 'Attach to running test' })

vim.keymap.set('n', '<Leader>nc', neotest.run.stop, { desc = 'Stop/cancel running test' })

vim.keymap.set('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end, { desc = 'Open test output' })

vim.keymap.set(
    'n',
    '<Leader>np',
    neotest.output_panel.toggle,
    { desc = 'Toggle output panel' }
)

vim.keymap.set('n', '<Leader>nt', function()
    neotest_run(neotest.summary.toggle, {}, false)
end, { desc = 'Toggle test summary' })

-- Filetype-mappings
local neotest_ft_augroup = vim.api.nvim_create_augroup('NeotestFtAu', {})
for _, ft in ipairs({ 'output', 'output-panel', 'attach', 'summary' }) do
    vim.api.nvim_create_autocmd('FileType', {
        desc = 'Configure neotest ' .. ft .. ' window',
        pattern = 'neotest-' .. ft,
        group = neotest_ft_augroup,
        callback = function(e)
            -- Mappings
            vim.keymap.set('n', 'q', function()
                pcall(vim.api.nvim_win_close, 0, true)
                vim.cmd.wincmd('p')
            end, {
                buffer = e.buf,
                desc = 'Close neotest window and return to previous',
            })
            -- Options
            if ft == 'summary' then
                vim.opt_local.number = true
                vim.opt_local.relativenumber = true
                vim.opt_local.winfixbuf = true
            end
        end,
    })
end
