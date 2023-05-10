local neotest = require('neotest')

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
        running = '󰜎',
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

-- Mappings
local u = require('utils')
u.keymap('n', '<Leader>nn', function()
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    neotest.run.run() -- nearest to cursor
end)
u.keymap('n', '<Leader>nl', function()
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    neotest.run.run_last()
end)
u.keymap('n', '<Leader>nf', function()
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    neotest.run.run(vim.fn.expand('%'))
end)
u.keymap('n', '<Leader>ns', function()
    vim.cmd('silent noautocmd update')
    vim.cmd('cclose')
    neotest.run.run({ suite = true })
end)
u.keymap('n', '<Leader>nc', function()
    neotest.run.stop()
end)
u.keymap('n', '<Leader>na', function()
    neotest.run.attach()
end)
u.keymap('n', '<Leader>no', function()
    neotest.output.open({ short = true })
end)
u.keymap('n', '<Leader>nt', function()
    neotest.summary.toggle()
    ---@diagnostic disable-next-line: param-type-mismatch
    -- FIXME: this focuses the neotest window but doesn't focus nearest test
    -- https://github.com/nvim-neotest/neotest/discussions/197#discussioncomment-5697625
    -- local win = vim.fn.bufwinid('Neotest Summary')
    -- if win > -1 then
    --     vim.api.nvim_set_current_win(win)
    -- end
end)
-- Filetype-mappings
local group = vim.api.nvim_create_augroup('NeotestConfig', {})
for _, ft in ipairs({ 'output', 'attach', 'summary' }) do
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neotest-' .. ft,
        group = group,
        callback = function()
            u.keymap('n', 'q', function()
                pcall(vim.api.nvim_win_close, 0, true)
            end, { buffer = true })
            vim.cmd('wincmd p')
        end,
    })
end
