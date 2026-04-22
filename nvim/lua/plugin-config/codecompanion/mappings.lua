local codecompanion = require('codecompanion')
local keymaps = require('codecompanion.interactions.chat.keymaps')
local telescope_action_state = require('telescope.actions.state')
local telescope_actions = require('telescope.actions')
local u = require('utils')

local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local rules = require('plugin-config.codecompanion.rules')
local state_helpers = require('plugin-config.codecompanion.helpers').state
local window_helpers = require('plugin-config.codecompanion.helpers').window

local M = {}

-- Chat window callbacks
local function hide_chats()
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
    end, 1)
end

local function send_message(chat_obj)
    vim.cmd.stopinsert()
    keymaps.send.callback(chat_obj)
end

local function open_options()
    keymaps.options.callback()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
    end, 1)
end

local function open_debug(chat_obj)
    keymaps.debug.callback(chat_obj)
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        local win_id = vim.api.nvim_get_current_win()
        local win_config = vim.api.nvim_win_get_config(win_id)
        if win_config.relative == 'editor' then
            win_config.col = 1
            vim.api.nvim_win_set_config(win_id, win_config)
        end
    end, 1)
end

-- Chat window keymaps
function M.chat_keymaps()
    return {
        -- Chat lifecycle
        create_chat = {
            modes = { n = '<A-c>', i = '<A-c>' },
            description = 'Create new chat',
            callback = function()
                vim.cmd.CodeCompanionChat()
                -- Hack to make completions work immediately in a new chat
                vim.cmd.stopinsert()
                vim.defer_fn(function()
                    vim.cmd.startinsert({ bang = true })
                end, 100)
            end,
        },
        hide_chats = {
            modes = { n = '<C-c>', i = '<C-c>' },
            description = 'Hide chats',
            callback = hide_chats,
        },
        close = { modes = { n = '<A-x>', i = '<A-x>' } },
        clear = { modes = { n = '<A-w>', i = '<A-w>' } },
        -- Message actions
        send = {
            modes = { n = '<C-o>', i = '<C-o>' },
            description = 'Send message',
            callback = send_message,
        },
        stop = { modes = { n = '<C-x>', i = '<C-x>' } },
        yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
        -- Navigation
        next_chat = { modes = { n = '<A-n>', i = '<A-n>' } },
        previous_header = { modes = { n = '<C-[>', i = '<C-[>' } },
        next_header = { modes = { n = '<C-]>', i = '<C-]>' } },
        fold_code = { modes = { n = 'zc' } },
        goto_file_under_cursor = { modes = { n = 'gf' } },
        -- Chat tools
        action_palette = {
            modes = { n = '<A-a>', i = '<A-a>' },
            description = 'Action palette',
            callback = function()
                vim.cmd.CodeCompanionActions()
            end,
        },
        options = {
            modes = { n = '<A-h>', i = '<A-h>' },
            callback = open_options,
        },
        change_adapter = { modes = { n = '<A-m>', i = '<A-m>' } },
        debug = {
            modes = { n = '<A-d>', i = '<A-d>' },
            callback = open_debug,
        },
        -- Rules
        rules = {
            modes = { n = '<Leader>rc', i = '<Leader>rc' },
        },
        reload_rules = {
            modes = { n = '<Leader>rl', i = '<Leader>rl' },
            description = 'Reload CodeCompanion rules',
            callback = function(chat)
                vim.cmd.stopinsert()
                rules.reload_chat_rules(chat)
            end,
        },
        -- Chat modes
        clear_approvals = { modes = { n = '<Leader>ra' } },
        yolo_mode = { modes = { n = '<Leader>ym' } },
        -- Buffer sync
        buffer_sync_all = { modes = { n = '<Leader>rp' } },
        buffer_sync_diff = { modes = { n = '<Leader>rw' } },
    }
end

-- Shared interactions keymaps
function M.shared_keymaps()
    return {
        view_diff = { modes = { n = 'ds' } },
        always_accept = { modes = { n = 'aa' } },
        accept_change = { modes = { n = 'dp' } },
        reject_change = { modes = { n = 'de' } },
        next_hunk = { modes = { n = ']h' } },
        previous_hunk = { modes = { n = '[h' } },
        cancel = { modes = { n = 'ct' } },
    }
end

-- CodeCompanion chat filetype-local mapping callbacks
local function insert_last_user_prompt()
    vim.cmd.stopinsert()
    local last = state_helpers.get_last_user_prompt()
    if not last or last == '' then
        return
    end
    vim.api.nvim_put(vim.split(last, '\n', { plain = true }), 'c', true, true)
    vim.defer_fn(function()
        vim.cmd.startinsert({ bang = true })
    end, 1)
end

local function toggle_chat_zoom()
    vim.cmd.stopinsert()
    window_helpers.toggle_cc_zoom()
end

-- CodeCompanion chat filetype-local mappings
local function setup_codecompanion_filetype_mappings(e)
    local bufnr = e.buf

    vim.keymap.set('i', '<C-h>', '<Esc><C-w>h', {
        buf = bufnr,
        desc = 'Move to left window',
    })

    vim.keymap.set({ 'i', 'n' }, '<A-p>', function()
        local chat_obj = codecompanion.buf_get_chat(bufnr)
        vim.print(string.format('Model Params:\n%s', vim.inspect(chat_obj.settings)))
    end, { buf = bufnr, desc = 'Show model params' })

    vim.keymap.set({ 'i', 'n' }, '<A-r>', function()
        vim.cmd.stopinsert()
        local system_role = state_helpers.get_current_system_role_prompt()
        if not system_role or system_role == '' then
            return
        end
        vim.print(system_role)
        vim.schedule(function()
            vim.cmd.normal({ args = { 'g<' }, bang = true })
        end)
    end, {
        buf = bufnr,
        desc = 'Show system role prompt in message window',
    })

    vim.keymap.set({ 'i', 'n' }, '<C-p>', insert_last_user_prompt, {
        buf = bufnr,
        desc = 'Insert last user prompt',
    })

    vim.keymap.set({ 'n', 'i' }, '<A-t>', toggle_chat_zoom, {
        buf = bufnr,
        desc = 'Toggle CodeCompanion zoom',
    })
end

-- CodeCompanion CLI terminal filetype mappings
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

-- CodeCompanion CLI input filetype mappings
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

-- Quickfix filetype mappings
local function setup_qf_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>qf', function()
        chat_helpers.run_slash_command('qfix')
    end, {
        buf = args.buf,
        desc = 'Explain quickfix diagnostics',
    })
end

-- Fugitive filetype mappings
local function setup_fugitive_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>cc', function()
        chat_helpers.run_slash_command('conventional_commit')
    end, {
        buf = args.buf,
        desc = 'Generate conventional commit message',
    })

    vim.keymap.set('n', '<Leader>bc', function()
        vim.ui.input(
            { prompt = 'Base branch for commit diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    chat_helpers.run_slash_command('conventional_commit', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buf = args.buf,
        desc = 'Conventional commit with base branch',
    })

    vim.keymap.set('n', '<Leader>cr', function()
        chat_helpers.run_slash_command('code_review')
    end, {
        buf = args.buf,
        desc = 'Perform code review',
    })

    vim.keymap.set('n', '<Leader>br', function()
        vim.ui.input(
            { prompt = 'Base branch for diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    chat_helpers.run_slash_command('code_review', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buf = args.buf,
        desc = 'Code review with base branch',
    })

    vim.keymap.set('n', '<Leader>cl', function()
        chat_helpers.run_slash_command('changelog')
    end, {
        buf = args.buf,
        desc = 'Generate changelog since last release',
    })
end

-- Filetype mappings registration
local function setup_filetype_mappings()
    local group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'codecompanion',
        desc = 'CodeCompanion filetype mappings',
        callback = setup_codecompanion_filetype_mappings,
    })

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

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'qf',
        desc = 'CodeCompanion quickfix mapping',
        callback = setup_qf_filetype_mappings,
    })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'fugitive',
        desc = 'CodeCompanion fugitive mappings',
        callback = setup_fugitive_filetype_mappings,
    })
end

-- CodeCompanion global mapping callbacks
local function explore_open_chats()
    codecompanion.actions()
    vim.defer_fn(function()
        local picker =
            telescope_action_state.get_current_picker(vim.api.nvim_get_current_buf())
        picker:move_selection(-1)
        telescope_actions.select_default(picker)
    end, 250)
end

local function paste_selection_to_chat()
    codecompanion.add()
    if vim.bo.filetype ~= 'codecompanion' then
        window_helpers.try_focus_chat_float()
        vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
    end
end

local function explain_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local code = u.get_selection()
    vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
    chat_helpers.run_slash_command('explain_code', { bufnr = bufnr, code = code })
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

-- CodeCompanion global mappings
local function setup_global_mappings()
    -- Chat and command entry mappings
    vim.keymap.set('n', '<Leader>cg', window_helpers.focus_or_toggle_chat, {
        desc = 'Toggle CodeCompanion chat',
    })

    vim.keymap.set({ 'n', 'v' }, '<Leader>cr', function()
        vim.api.nvim_input(':CodeCompanion ')
    end, {
        desc = 'Run CodeCompanion command-line',
    })

    vim.keymap.set({ 'n', 'v' }, '<Leader>ca', vim.cmd.CodeCompanionActions, {
        desc = 'Open CodeCompanion actions',
    })

    vim.keymap.set('n', '<Leader>cb', vim.cmd.CodeCompanionHistory, {
        desc = 'Browse CodeCompanion history',
    })

    vim.keymap.set('n', '<Leader>ce', explore_open_chats, {
        desc = 'Explore CodeCompanion open chats',
    })

    vim.keymap.set('n', '<Leader>ea', rules.edit_repo_rule_file, {
        desc = 'Edit repo AI rules file',
    })

    -- CLI mappings
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

    -- Selection and context mappings
    vim.keymap.set('n', '<Leader>ac', function()
        chat_helpers.add_context({ vim.api.nvim_buf_get_name(0) })
    end, {
        desc = 'Add current file to CodeCompanion',
    })

    vim.keymap.set('v', '<Leader>cp', paste_selection_to_chat, {
        desc = 'Paste selection to CodeCompanion chat',
    })

    vim.keymap.set('v', '<Leader>ec', explain_selection, {
        desc = 'Explain selected code with CodeCompanion',
    })

    vim.keymap.set('v', '<Leader>et', explain_selection_with_cli, {
        desc = 'Explain selected code with CodeCompanion CLI',
    })
end

-- Public setup
function M.setup()
    setup_filetype_mappings()
    setup_global_mappings()
end

return M
