local neogit = require('neogit')

neogit.setup({
    kind = 'split',
    disable_hint = true,
    disable_signs = true,
    disable_line_numbers = false,
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
