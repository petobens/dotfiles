require('mcphub').setup({})

vim.keymap.set('n', '<Leader>mc', vim.cmd.MCPHub, { desc = 'Open MCP Hub' })
