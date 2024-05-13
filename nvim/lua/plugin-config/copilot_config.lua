require('copilot').setup({
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
        ['*'] = false, -- disable for all except explictly defined
        ghaction = true,
        lua = true,
        python = true,
        sh = true,
    },
})

require('copilot_cmp').setup()
