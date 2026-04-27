local codecompanion = require('codecompanion')

local M = {}

-- Constants
local GITHUB_TOKEN = 'GITHUB_TOKEN="$(pass show git/github/petobens/api-key)"'

-- Helpers
local function with_env(cmd, env)
    return {
        cmd = 'sh',
        args = { '-lc', table.concat(env, ' ') .. ' exec "$@"', 'sh', cmd },
    }
end

local function explain_selection_with_cli()
    codecompanion.cli('Can you explain this code?', {
        focus = false,
        submit = true,
    })
    vim.schedule(function()
        vim.api.nvim_input(vim.keycode('<Esc>'))
    end)
end

local function setup_codecompanion_cli_mappings(args)
    vim.keymap.set('t', '<C-c>', function()
        vim.api.nvim_feedkeys(vim.keycode('<C-\\><C-n>'), 'n', false)
        vim.schedule(function()
            codecompanion.toggle_cli()
        end)
    end, {
        buffer = args.buf,
        desc = 'Hide CodeCompanion CLI',
    })
end

local function setup_codecompanion_cli_input_mappings(args)
    vim.keymap.set({ 'n', 'i' }, '<C-o>', function()
        if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
            vim.cmd.stopinsert()
        end
        vim.cmd.write({ bang = true })
    end, {
        buffer = args.buf,
        desc = 'Write CodeCompanion CLI prompt',
    })
end

-- Config
function M.build()
    return {
        agent = 'codex',
        agents = {
            codex = with_env('codex', { GITHUB_TOKEN }),
            claude_code = with_env('claude', { GITHUB_TOKEN }),
        },
    }
end

-- Mappings
function M.setup_mappings(group)
    -- Global
    vim.keymap.set('n', '<Leader>ct', function()
        codecompanion.toggle_cli()
    end, {
        desc = 'Toggle CodeCompanion CLI',
    })

    vim.keymap.set('n', '<Leader>ck', function()
        vim.cmd.CodeCompanionCLI({ 'Ask' })
    end, {
        desc = 'Open CodeCompanion CLI Ask',
    })

    vim.keymap.set('v', '<Leader>et', explain_selection_with_cli, {
        desc = 'Explain selected code with CodeCompanion CLI',
    })

    -- Autocmds
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'codecompanion_cli',
        desc = 'CodeCompanion CLI mappings',
        callback = setup_codecompanion_cli_mappings,
    })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'codecompanion_input',
        desc = 'CodeCompanion CLI input mappings',
        callback = setup_codecompanion_cli_input_mappings,
    })
end

return M
