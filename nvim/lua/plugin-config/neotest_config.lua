local neotest = require('neotest')
local u = require('utils')

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
    group = vim.api.nvim_create_augroup('NeotestConfig', {}),
    pattern = 'neotest-output-panel',
    callback = function()
        vim.cmd('resize 15 | set winfixheight | normal! G')
    end,
})

-- Helpers
local function _parse_neotest_output(task, last_winid)
    -- Set the diagnostic qf
    local diagnostics = vim.diagnostic.get(task.bufnr)
    vim.diagnostic.setqflist()
    local qf_diagnostic = vim.fn.getqflist()
    local diagnostic_entries = {}
    for _, v in pairs(qf_diagnostic) do
        table.insert(
            diagnostic_entries,
            { bufnr = v.bufnr, lnum = v.lnum, text = v.text }
        )
    end

    -- Create another qf from output but avoid repeating diagnostics entries
    local efm = { python = [[%E%f:%l:\ %m,%-G%.%#,]] }
    local has_stdout = false
    local pdb = false
    local lines = vim.api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, true)
    for _, v in ipairs(lines) do
        if task.ft == 'python' then
            if string.find(v, 'Captured stdout call') and not has_stdout then
                has_stdout = true
            end
            if string.match(v, 'bdb.BdbQuit') then
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
        local repeatead = false
        for _, e in pairs(diagnostic_entries) do
            if v.bufnr == e.bufnr and v.lnum == e.lnum and v.text == e.text then
                repeatead = true
            end
        end
        if not repeatead then
            table.insert(qf_output, v)
        end
    end

    -- Combine both qf lists and open qf or output buffer accordingly
    local qf = vim.list_extend(qf_diagnostic, qf_output)
    if not vim.tbl_isempty(qf) then
        vim.fn.setqflist({}, ' ', { title = task.name, items = qf })
        if not pdb then
            vim.cmd('copen')
            vim.fn.win_gotoid(last_winid)
        else
            -- Reset qf and diagnostics
            vim.fn.setqflist({})
            vim.cmd('cclose')
            if diagnostics then
                vim.defer_fn(function()
                    vim.diagnostic.reset(diagnostics[1].namespace, diagnostics[1].bufnr)
                end, 100)
            end
        end
    else
        if has_stdout then
            require('overseer').run_action(task, 'open hsplit')
            vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight')
            vim.opt_local.winfixbuf = true
            vim.opt_local.modifiable = true
            vim.cmd('silent normal! kdGggG')
            vim.opt_local.modifiable = false
            vim.keymap.set('n', 'q', function()
                local calling_winid = _G.LastWinId
                vim.cmd('close')
                vim.fn.win_gotoid(calling_winid)
            end, { buffer = true })
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
        _parse_neotest_output(neotest_task, vim.fn.win_getid())
    end)
end

local function neotest_run(func, opts, subscribe)
    local ft = vim.bo.filetype
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    vim.cmd('cd %:p:h')

    func(opts)

    local post = (subscribe == nil and true) or subscribe
    if post then
        _neotest_overseer_subscribe(ft, bufnr)
    end
end

-- Mappings
vim.keymap.set('n', '<Leader>nn', function()
    neotest_run(neotest.run.run)
end)
vim.keymap.set('n', '<Leader>nl', function()
    neotest_run(neotest.run.run_last)
end)
vim.keymap.set('n', '<Leader>nf', function()
    neotest_run(neotest.run.run, { vim.fn.expand('%') })
end)
vim.keymap.set('n', '<Leader>ns', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '--cov')
    end
    neotest_run(neotest.run.run, { suite = true, extra_args = extra_args })
end)
vim.keymap.set('n', '<Leader>nd', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '-x')
        table.insert(extra_args, '--pdb')
    end
    neotest_run(neotest.run.run, { extra_args = extra_args })
end)
vim.keymap.set('n', '<Leader>na', function()
    neotest_run(neotest.run.attach)
    vim.cmd([[nmap <silent> q :close<CR>]])
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight | startinsert')
end)
vim.keymap.set('n', '<Leader>nc', function()
    neotest.run.stop()
end)
vim.keymap.set('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end)
vim.keymap.set('n', '<Leader>np', function()
    neotest.output_panel.toggle()
end)
vim.keymap.set('n', '<Leader>nt', function()
    neotest_run(neotest.summary.toggle, {}, false)
end)

-- Filetype-mappings
for _, ft in ipairs({ 'output', 'output-panel', 'attach', 'summary' }) do
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neotest-' .. ft,
        group = vim.api.nvim_create_augroup('NeotestFtAu', {}),
        callback = function(e)
            vim.keymap.set('n', 'q', function()
                pcall(vim.api.nvim_win_close, 0, true)
                vim.cmd('wincmd p')
            end, { buffer = e.buf })
            if ft == 'summary' then
                vim.opt_local.number = true
                vim.opt_local.relativenumber = true
                vim.opt_local.winfixbuf = true
            end
        end,
    })
end
