local codecompanion = require('codecompanion')
local keymaps = require('codecompanion.interactions.chat.keymaps')
local telescope_action_state = require('telescope.actions.state')
local telescope_actions = require('telescope.actions')

local chat_helpers = require('plugin-config.codecompanion.helpers').chat
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
        -- Chat modes
        _btw = {
            modes = { n = '<Leader>bt' },
        },
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
local function show_adapter_info(chat_obj)
    local adapter = chat_obj.adapter
    local model = state_helpers.get_adapter_model(adapter)
    local params = adapter.type == 'acp' and adapter.defaults or chat_obj.settings
    local adapter_info = {
        { 'type', adapter.type },
        { 'name', adapter.name },
        { 'model', model },
        { 'model_params', params },
    }
    local lines = vim.iter(adapter_info)
        :map(function(item)
            return string.format('%s = %s', item[1], vim.inspect(item[2]))
        end)
        :totable()
    vim.print(string.format('Adapter Info\n%s', table.concat(lines, '\n')))
end

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
        show_adapter_info(chat_obj)
    end, { buf = bufnr, desc = 'Show adapter info' })

    vim.keymap.set({ 'i', 'n' }, '<C-p>', insert_last_user_prompt, {
        buf = bufnr,
        desc = 'Insert last user prompt',
    })

    vim.keymap.set({ 'n', 'i' }, '<A-t>', toggle_chat_zoom, {
        buf = bufnr,
        desc = 'Toggle CodeCompanion zoom',
    })
end

local function setup_filetype_mappings(group)
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'codecompanion',
        desc = 'CodeCompanion filetype mappings',
        callback = setup_codecompanion_filetype_mappings,
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

local function show_ai_usage()
    vim.api.nvim_echo({ { 'Retrieving rate limits...' } }, false, {})
    vim.system({ 'ai_usage' }, { text = true }, function(obj)
        local out = (obj.stdout or ''):gsub('\27%[[0-9;]*m', ''):gsub('%s+$', '')
        vim.schedule(function()
            if out == '' then
                vim.api.nvim_echo({ { '' } }, false, {})
                vim.notify('ai_usage: no output', vim.log.levels.WARN)
            else
                vim.api.nvim_echo({ { out } }, false, {})
            end
        end)
    end)
end

-- CodeCompanion global mappings
local function setup_global_mappings()
    -- AI rate limits
    vim.keymap.set('n', '<Leader>ai', show_ai_usage, {
        desc = 'Show AI usage (rate limits)',
    })

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

    -- Selection and context mappings
    vim.keymap.set('n', '<Leader>ac', function()
        chat_helpers.add_context({ vim.api.nvim_buf_get_name(0) })
    end, {
        desc = 'Add current file to CodeCompanion',
    })

    vim.keymap.set('v', '<Leader>cp', paste_selection_to_chat, {
        desc = 'Paste selection to CodeCompanion chat',
    })
end

-- Public setup
function M.setup(group)
    setup_filetype_mappings(group)
    setup_global_mappings()
end

return M
