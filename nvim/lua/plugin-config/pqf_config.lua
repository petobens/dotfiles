local u = require('utils')

require('pqf').setup({
    signs = {
        error = { text = u.icons.error },
        warning = { text = u.icons.warning },
        info = { text = u.icons.info },
        hint = { text = u.icons.hint },
    },
    show_multiple_lines = true,
})
