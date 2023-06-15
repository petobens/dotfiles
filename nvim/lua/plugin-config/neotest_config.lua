local neotest = require('neotest')
local u = require('utils')

neotest.setup({
    adapters = {
        require('neotest-python'),
    },
    consumers = {
        ---@diagnostic disable-next-line: assign-type-mismatch
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
            vim.cmd('copen')
            vim.cmd('wincmd p')
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

-- Autocmds
local group = vim.api.nvim_create_augroup('NeotestConfig', {})
vim.api.nvim_create_autocmd('FileType', {
    group = group,
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

-- Mappings
u.keymap('n', '<Leader>nn', function()
    neotest_run(neotest.run.run)
end)
u.keymap('n', '<Leader>nl', function()
    neotest_run(neotest.run.run_last)
end)
u.keymap('n', '<Leader>nf', function()
    neotest_run(neotest.run.run, { vim.fn.expand('%') })
end)
u.keymap('n', '<Leader>ns', function()
    neotest_run(neotest.run.run, { suite = true })
end)
u.keymap('n', '<Leader>nc', function()
    neotest.run.stop()
end)
u.keymap('n', '<Leader>na', function()
    neotest.run.attach()
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight | startinsert')
end)
u.keymap('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end)
u.keymap('n', '<Leader>np', function()
    neotest.output_panel.toggle()
end)
u.keymap('n', '<Leader>nt', function()
    neotest_run(neotest.summary.toggle)
end)

-- Filetype-mappings
for _, ft in ipairs({ 'output', 'output-panel', 'attach', 'summary' }) do
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neotest-' .. ft,
        group = group,
        callback = function()
            u.keymap('n', 'q', function()
                pcall(vim.api.nvim_win_close, 0, true)
                vim.cmd('wincmd p')
            end, { buffer = true })
        end,
    })
end
