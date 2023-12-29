local u = require('utils')

require('pqf').setup({
    signs = {
        error = u.icons.error,
        warning = u.icons.warning,
        info = u.icons.info,
        hint = u.icons.hint,
    },
    show_multiple_lines = true,
})
