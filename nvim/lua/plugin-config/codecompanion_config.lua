local codecompanion = require('codecompanion')

-- FIXME: Not saving sessions?
-- See: https://github.com/olimorris/codecompanion.nvim/discussions/139
-- TODO:
-- Title color: https://github.com/olimorris/codecompanion.nvim/discussions/815
-- Get into insert mode after "sending" a request/question?
-- Custom prompts (a.k.a sessions):
-- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/plugins/coding.lua#L81
-- Some virtual indicator that the chat is "loading" (e.g. spinner) as chatgpt

_G.CodeCompanionConfig = {}

codecompanion.setup({
    adapters = {
        openai = function()
            return require('codecompanion.adapters').extend('openai', {
                env = {
                    api_key = 'cmd:pass show openai/yahoomail/apikey',
                },
                schema = {
                    model = {
                        default = 'gpt-4o',
                        -- default = 'o3-mini-2025-01-31',
                    },
                },
            })
        end,
    },
    display = {
        chat = {
            intro_message = '',
            show_settings = false,
            window = {
                layout = 'float',
                border = 'rounded',
                title = { { 'CodeCompanion', 'TelescopeTitle' } },
                height = 0.945,
                width = 0.45,
                relative = 'editor',
                col = vim.o.columns, -- right position
                opts = {
                    relativenumber = false,
                    number = false,
                },
            },
        },
    },
    strategies = {
        chat = {
            adapter = 'openai',
            roles = {
                llm = function(adapter)
                    return string.format(
                        '%s (%s)',
                        adapter.formatted_name,
                        adapter.schema.model.default
                    )
                end,
                user = '',
            },
            keymaps = {
                send = {
                    modes = { n = '<C-o>', i = '<C-o>' },
                },
                close = {
                    modes = { n = '<C-c>', i = '<C-c>' },
                    callback = function()
                        codecompanion.toggle()
                    end,
                },
            },
        },
        -- inline = {
        --     adapter = 'copilot',
        -- },
    },
})

-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register('markdown', 'codecompanion')

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true }),
    pattern = { 'codecompanion' },
    callback = function(e)
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    group = vim.api.nvim_create_augroup('codecompanion-winleave', { clear = true }),
    pattern = { '*' },
    callback = function()
        if vim.bo.filetype == 'codecompanion' then
            vim.fn.win_gotoid(_G.CodeCompanionConfig.last_winid)
            vim.defer_fn(function()
                vim.cmd('stopinsert')
            end, 2)
        end
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>xx', function()
    -- Save last win_id to jump back
    _G.CodeCompanionConfig.last_winid = vim.fn.win_getid()

    -- Focus window if already open (we simply search for a floating window)
    for w = 1, vim.fn.winnr('$') do
        local win_id = vim.fn.win_getid(w)
        local win_conf = vim.api.nvim_win_get_config(win_id)
        if win_conf.focusable and win_conf.relative ~= '' then
            vim.api.nvim_set_current_win(win_id)
            return
        end
    end

    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd('startinsert')
    end, 1)
end)
