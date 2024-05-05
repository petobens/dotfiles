local neogit = require('neogit')

_G.dbeeConfig = {}

neogit.setup({
    disable_hint = true,
    disable_signs = true,
    disable_line_numbers = false,
    disable_context_highlighting = true,
    sections = {
        recent = {
            hidden = true,
        },
    },
    status = {
        recent_commit_count = 5,
        show_head_commit_hash = false,
        HEAD_padding = 0,
        mode_padding = 1,
        mode_text = {
            M = 'M ',
            N = 'N',
            A = 'A',
            D = 'D',
            C = 'C',
            U = 'U',
            R = 'R',
            DD = 'DD',
            AU = 'AU',
            UD = 'UD',
            UA = 'UA',
            DU = 'DU',
            AA = 'AA',
            UU = 'UU',
            ['?'] = '?',
        },
    },
    commit_editor = {
        kind = 'split',
        show_staged_diff = false,
    },
    mappings = {
        status = {
            ['X'] = 'Discard',
            ['='] = 'Toggle',
            ['[h'] = 'GoToPreviousHunkHeader',
            [']h'] = 'GoToNextHunkHeader',
            ['zm'] = 'Depth2',
            ['zr'] = 'Depth4',
        },
        commit_editor = {
            ['q'] = 'Close',
            ['<Leader>wq'] = 'Submit',
            ['<Leader>ac'] = 'Abort',
        },
        popup = {
            ['b'] = false,
            ['l'] = false,
            ['P'] = 'PullPopup',
            ['p'] = 'PushPopup',
            ['w'] = false,
        },
    },
})

-- Autocmds
vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    group = vim.api.nvim_create_augroup('neogitstatus_winleave', { clear = true }),
    pattern = { '*' },
    callback = function()
        if vim.bo.filetype == 'NeogitStatus' then
            vim.fn.win_gotoid(_G.dbeeConfig.last_winid)
        end
    end,
})
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = vim.api.nvim_create_augroup('neogit_commit_editor', { clear = true }),
    pattern = { 'NeogitCommitMessage' },
    callback = function()
        vim.cmd('wincmd J | resize 15 | set winfixheight')
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>ngs', function()
    _G.dbeeConfig.last_winid = vim.fn.win_getid()
    neogit.open({ kind = 'split' })
    vim.cmd('wincmd J | resize 15 | set winfixheight')
end)
vim.keymap.set('n', '<leader>ngp', neogit.action('push', 'to_pushremote'))
vim.keymap.set(
    'n',
    '<leader>ngF',
    neogit.action('push', 'to_pushremote', { '--force-with-lease' })
)
vim.keymap.set('n', '<leader>ngP', neogit.action('pull', 'from_pushremote'))
