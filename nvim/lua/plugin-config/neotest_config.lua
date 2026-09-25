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
    for _, v in ipairs(qf_diagnostic) do
        table.insert(
            diagnostic_entries,
            { bufnr = v.bufnr, lnum = v.lnum, text = v.text }
        )
    end

    -- Open output when pytest shows captured stdout or the coverage header
    local has_output, pdb = false, false
    local lines = vim.api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, true)
    for _, line in ipairs(lines) do
        if task.ft == 'python' then
            if
                not has_output
                and (
                    line:find('Captured stdout call', 1, true)
                    or line:find('tests coverage', 1, true)
                )
            then
                has_output = true
            end
            -- Detect PDB quit to avoid opening quickfix and to clear diagnostics instead
            if not pdb and line:find('bdb.BdbQuit', 1, true) then
                pdb = true
            end
            if has_output and pdb then
                break
            end
        end
    end

    -- Parse output into quickfix items, then merge with diagnostics avoiding repeats
    local efm = { python = [[%E%f:%l:\ %m,%-G%.%#,]] }
    vim.fn.setqflist({}, ' ', {
        lines = lines,
        efm = efm[task.ft],
    })
    local qf_output = {}
    for _, v in ipairs(vim.fn.getqflist()) do
        if not is_qf_duplicate(v, diagnostic_entries) then
            table.insert(qf_output, v)
        end
    end

    -- If we have output then open it
    if has_output then
        require('overseer').run_action(task, 'open hsplit')
        vim.defer_fn(function()
            vim.cmd.stopinsert()
        end, 5)
        set_output_window_layout()
        vim.opt_local.modifiable = true
        vim.cmd.normal({ args = { 'kdGggG' }, bang = true, mods = { silent = true } })
        vim.opt_local.modifiable = false
        vim.keymap.set('n', 'q', function()
            local calling_winid = _G.LastWinId
            vim.cmd.close()
            pcall(vim.api.nvim_set_current_win, calling_winid)
        end, {
            buf = 0,
            desc = 'Close neotest output window and return to previous window',
        })
    end

    -- Combine both qf lists and open qf if needed
    local qf = vim.list_extend(qf_diagnostic, qf_output)
    if not vim.tbl_isempty(qf) then
        vim.fn.setqflist({}, ' ', { title = task.name, items = qf })
        if not pdb then
            vim.cmd.copen()
            vim.api.nvim_set_current_win(last_winid)
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

local function _neotest_overseer_subscribe(func, opts, ft, bufnr)
    local overseer = require('overseer')
    local previous = {}
    local neotest_task
    local function on_start(task)
        neotest_task = task
    end
    for _, task in ipairs(overseer.list_tasks({ include_ephemeral = true })) do
        if task.metadata.neotest_group_id then
            previous[task.id] = task
            task:subscribe('on_start', on_start)
        end
    end

    local function unsubscribe()
        for _, task in pairs(previous) do
            task:unsubscribe('on_start', on_start)
        end
    end

    local ok, err = pcall(func, opts)
    if not ok then
        unsubscribe()
        error(err)
    end

    local attempts = 0
    local function poll()
        if not neotest_task then
            for _, task in ipairs(overseer.list_tasks({ include_ephemeral = true })) do
                if task.metadata.neotest_group_id and not previous[task.id] then
                    neotest_task = task
                    break
                end
            end
        end
        if not neotest_task then
            attempts = attempts + 1
            if attempts < 100 then
                vim.defer_fn(poll, 50)
            else
                unsubscribe()
                vim.notify(
                    'No Neotest task appeared within 5 seconds',
                    vim.log.levels.WARN
                )
            end
            return
        end
        unsubscribe()
        neotest_task.ft = ft
        neotest_task.bufnr = bufnr
        local function on_complete()
            vim.schedule(function()
                _parse_neotest_output(neotest_task, vim.api.nvim_get_current_win())
            end)
            return true
        end
        if neotest_task:is_complete() then
            on_complete()
        else
            neotest_task:subscribe('on_complete', on_complete)
        end
    end
    poll()
end

local function neotest_run(func, opts, subscribe)
    local ft = vim.bo.filetype
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo.buftype == '' then
        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        if dir and vim.fn.isdirectory(dir) == 1 then
            vim.cmd.update({ mods = { silent = true, noautocmd = true } })
            vim.api.nvim_set_current_dir(dir)
        end
    end
    vim.cmd.cclose()

    if subscribe == false then
        func(opts or {})
    else
        _neotest_overseer_subscribe(func, opts or {}, ft, bufnr)
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
            clear_marked = '<C-Space>',
            clear_target = 'u',
            expand = { 'zo', 'zc' }, -- also collapse
            expand_all = 'zr',
            jumpto = { '<CR>', '<C-]>' },
            mark = '<Space>',
            run = 'r',
            run_marked = 'R',
            short = 'o', -- open with short output
            stop = 's',
            target = 't',
        },
    },
    icons = {
        child_indent = '  ',
        child_prefix = '',
        collapsed = '',
        expanded = '',
        failed = ' ',
        final_child_prefix = '',
        non_collapsible = '',
        passed = ' ',
        running = u.icons.running,
        skipped = ' ',
        unknown = ' ',
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
    group = vim.api.nvim_create_augroup('NeotestConfig'),
    pattern = 'neotest-output-panel',
    callback = set_output_window_layout,
})

-- Mappings
vim.keymap.set('n', '<Leader>nn', function()
    neotest_run(neotest.run.run)
end, { desc = '[N]eotest [n]earest test: run' })

vim.keymap.set('n', '<Leader>nl', function()
    neotest_run(neotest.run.run_last)
end, { desc = '[N]eotest: run [l]ast test' })

vim.keymap.set('n', '<Leader>nf', function()
    neotest_run(neotest.run.run, { vim.api.nvim_buf_get_name(0) })
end, { desc = '[N]eotest: run [f]ile' })

vim.keymap.set('n', '<Leader>ns', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '--cov')
    end
    neotest_run(neotest.run.run, { suite = true, extra_args = extra_args })
end, { desc = '[N]eotest: run test [s]uite' })

vim.keymap.set('n', '<Leader>nd', function()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '-x')
        table.insert(extra_args, '--pdb')
    end
    neotest_run(neotest.run.run, { extra_args = extra_args })
end, { desc = '[N]eotest: run with [d]ebugger' })

vim.keymap.set('n', '<Leader>na', function()
    neotest_run(neotest.run.attach, {}, false)
end, { desc = '[N]eotest: [a]ttach to running test' })

vim.keymap.set('n', '<Leader>nc', neotest.run.stop, {
    desc = '[N]eotest: [c]ancel running test',
})

vim.keymap.set('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end, { desc = '[N]eotest: open [o]utput' })

vim.keymap.set(
    'n',
    '<Leader>np',
    neotest.output_panel.toggle,
    { desc = '[N]eotest: toggle output [p]anel' }
)

vim.keymap.set('n', '<Leader>nt', function()
    neotest_run(neotest.summary.toggle, {}, false)
end, { desc = '[N]eotest: toggle [t]est summary' })

-- Filetype-mappings
local neotest_ft_augroup = vim.api.nvim_create_augroup('NeotestFtAu')
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
                buf = e.buf,
                desc = 'Close neotest window and return to previous window',
            })
            -- The attachment window opens asynchronously and gains focus after FileType
            if ft == 'attach' then
                vim.schedule(function()
                    for _, win in ipairs(vim.fn.win_findbuf(e.buf)) do
                        vim.api.nvim_win_call(win, set_output_window_layout)
                        if vim.api.nvim_get_current_win() == win then
                            vim.cmd.startinsert()
                        end
                    end
                end)
            end
            -- Options
            if ft == 'summary' then
                vim.opt_local.number = true
                vim.opt_local.relativenumber = true
                vim.opt_local.winfixbuf = true
            end
        end,
    })
end
