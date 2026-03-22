local codecompanion = require('codecompanion')
local keymaps = require('codecompanion.interactions.chat.keymaps')
local telescope_action_state = require('telescope.actions.state')
local telescope_actions = require('telescope.actions')
local u = require('utils')

local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local state_helpers = require('plugin-config.codecompanion.helpers').state
local window_helpers = require('plugin-config.codecompanion.helpers').window

local M = {}

-- Chat window callbacks
M.chat_window = {}

function M.chat_window.hide_chats()
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
    end, 1)
end

function M.chat_window.send_message(chat_obj)
    vim.cmd.stopinsert()
    keymaps.send.callback(chat_obj)
end

function M.chat_window.open_options()
    keymaps.options.callback()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
    end, 1)
end

function M.chat_window.open_debug(chat_obj)
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
        local system_role = state_helpers.get_current_system_role_prompt()
        if system_role then
            vim.print(system_role)
        end
    end, {
        buf = bufnr,
        desc = 'Show system role prompt',
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

-- CodeCompanion global mappings
local function setup_global_mappings()
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

    vim.keymap.set('v', '<Leader>cp', paste_selection_to_chat, {
        desc = 'Paste selection to CodeCompanion chat',
    })

    vim.keymap.set('v', '<Leader>ec', explain_selection, {
        desc = 'Explain selected code with CodeCompanion',
    })

    vim.keymap.set('n', '<Leader>ac', function()
        chat_helpers.add_context({ vim.api.nvim_buf_get_name(0) })
    end, {
        desc = 'Add current file to CodeCompanion',
    })
end

-- Public setup
function M.setup()
    setup_filetype_mappings()
    setup_global_mappings()
end

return M
