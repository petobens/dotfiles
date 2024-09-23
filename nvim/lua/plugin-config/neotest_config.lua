local neotest = require('neotest')
local u = require('utils')

neotest.setup({
    adapters = {
        require('neotest-python'),
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
        enabled = true,
        open = function()
            local pdb = false
            local pdb_exit_msg = 'bdb.BdbQuit'
            if vim.bo.filetype == 'python' then
                for _, v in pairs(vim.fn.getqflist()) do
                    if string.match(v.text, pdb_exit_msg) then
                        pdb = true
                    end
                end
            end
            if not pdb then
                vim.cmd('copen')
                vim.cmd('wincmd p')
            else
                local diagnostics = vim.diagnostic.get(0)
                if
                    #diagnostics == 1
                    and string.match(diagnostics[1].message, pdb_exit_msg)
                then
                    vim.defer_fn(function()
                        vim.diagnostic.reset(
                            diagnostics[1].namespace,
                            diagnostics[1].bufnr
                        )
                    end, 100)
                end
            end
        end,
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
local function neotest_run(func, opts)
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    vim.cmd('cd %:p:h')
    func(opts)
end
local function neotest_nearest()
    local extra_args = {}
    if vim.bo.filetype == 'python' then
        table.insert(extra_args, '-rA')
        table.insert(extra_args, '--no-header')
    end
    neotest_run(neotest.run.run, { extra_args = extra_args })
end
local function neotest_attach()
    neotest.run.attach()
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight | startinsert')
end

-- Mappings
vim.keymap.set('n', '<Leader>nn', neotest_nearest)
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
vim.keymap.set('n', '<Leader>nr', function()
    neotest_nearest()
    vim.defer_fn(function()
        local overseer = require('overseer')
        local tasks = overseer.list_tasks({ recent_first = true })
        if tasks[1].status == 'RUNNING' then
            neotest_attach()
        else
            if vim.tbl_isempty(vim.fn.getqflist()) then
                overseer.run_action(tasks[1], 'open hsplit')
                vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight')
                vim.opt_local.winfixbuf = true
                vim.opt_local.modifiable = true
                vim.cmd('silent normal! kdGggG')
                vim.opt_local.modifiable = false
                vim.cmd([[nmap <silent> q :close<CR>]])
            end
        end
    end, 400)
end)
vim.keymap.set('n', '<Leader>nc', function()
    neotest.run.stop()
end)
vim.keymap.set('n', '<Leader>na', neotest_attach)
vim.keymap.set('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end)
vim.keymap.set('n', '<Leader>np', function()
    neotest.output_panel.toggle()
end)
vim.keymap.set('n', '<Leader>nt', function()
    neotest_run(neotest.summary.toggle)
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
