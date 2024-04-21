local neogit = require('neogit')
local u = require('utils')

neogit.setup({
    disable_hint = true,
    disable_signs = false,
    disable_line_numbers = false,
    kind = 'split',
    sections = {
        recent = {
            hidden = true,
        },
    },
    signs = {
        hunk = { '', '' },
        item = { '', '' },
        section = { u.icons.fold_open, u.icons.fold_close },
    },
    show_head_commit_hash = false,
    status = {
        recent_commit_count = 5,
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
    mappings = {
        status = {
            ['='] = 'Toggle',
        },
        popup = {
            ['l'] = false,
            ['b'] = false,
            ['w'] = false,
        },
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>ng', function()
    neogit.open()
    vim.cmd('wincmd J | resize 15 | set winfixheight')
end)
