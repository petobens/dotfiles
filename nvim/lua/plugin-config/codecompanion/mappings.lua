local codecompanion = require('codecompanion')
local telescope_action_state = require('telescope.actions.state')
local telescope_actions = require('telescope.actions')
local u = require('utils')

local helpers = require('plugin-config.codecompanion.helpers')
local keymaps = require('codecompanion.interactions.chat.keymaps')

local M = {}

-- Chat window callbacks referenced by CodeCompanion setup
M.chat_window = {}

function M.chat_window.hide_chats()
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
    end, 1)
end

function M.chat_window.send_message(chat)
    vim.cmd.stopinsert()
    keymaps.send.callback(chat)
end

function M.chat_window.open_options()
    keymaps.options.callback()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
    end, 1)
end

function M.chat_window.open_debug(chat)
    keymaps.debug.callback(chat)
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        local win = vim.api.nvim_get_current_win()
        local win_config = vim.api.nvim_win_get_config(win)
        if win_config.relative == 'editor' then
            win_config.col = 1
            vim.api.nvim_win_set_config(win, win_config)
        end
    end, 1)
end

-- Codecompanion filetype mapping callbacks
local function show_model_params(bufnr)
    local chat = codecompanion.buf_get_chat(bufnr)
    vim.print(string.format('Model Params:\n%s', vim.inspect(chat.settings)))
end

local function show_system_role_prompt()
    local system_role = helpers.get_current_system_role_prompt()
    if system_role then
        vim.print(system_role)
    end
end

local function insert_last_user_prompt()
    vim.cmd.stopinsert()
    local last = helpers.get_last_user_prompt()
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
    helpers.toggle_cc_zoom()
end

local function explain_qfix()
    helpers.run_slash_command('qfix')
end

local function run_command_line()
    vim.api.nvim_input(':CodeCompanion ')
end

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
        helpers.try_focus_chat_float()
        vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
    end
end

local function explain_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local code = u.get_selection()
    vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
    helpers.run_slash_command('explain_code', { bufnr = bufnr, code = code })
end

local function add_current_buffer_context()
    helpers.add_context({ vim.api.nvim_buf_get_name(0) })
end

-- CodeCompanion chat filetype mappings
local function setup_codecompanion_filetype_mappings(e)
    local bufnr = e.buf

    vim.keymap.set('i', '<C-h>', '<Esc><C-w>h', {
        buffer = bufnr,
        desc = 'Move to left window',
    })

    vim.keymap.set({ 'i', 'n' }, '<A-p>', function()
        show_model_params(bufnr)
    end, { buffer = bufnr, desc = 'Show model params' })

    vim.keymap.set({ 'i', 'n' }, '<A-r>', show_system_role_prompt, {
        buffer = bufnr,
        desc = 'Show system role prompt',
    })

    vim.keymap.set({ 'i', 'n' }, '<C-p>', insert_last_user_prompt, {
        buffer = bufnr,
        desc = 'Insert last user prompt',
    })

    vim.keymap.set({ 'n', 'i' }, '<A-t>', toggle_chat_zoom, {
        buffer = bufnr,
        desc = 'Toggle CodeCompanion zoom',
    })
end

-- Quickfix filetype mappings
local function setup_qf_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>qf', explain_qfix, {
        buffer = args.buf,
        desc = 'Explain quickfix diagnostics',
    })
end

-- Fugitive filetype mappings
local function setup_fugitive_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>cc', function()
        helpers.run_slash_command('conventional_commit')
    end, {
        buffer = args.buf,
        desc = 'Generate conventional commit message',
    })

    vim.keymap.set('n', '<Leader>bc', function()
        vim.ui.input(
            { prompt = 'Base branch for commit diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    helpers.run_slash_command('conventional_commit', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buffer = args.buf,
        desc = 'Conventional commit with base branch',
    })

    vim.keymap.set('n', '<Leader>cr', function()
        helpers.run_slash_command('code_review')
    end, {
        buffer = args.buf,
        desc = 'Perform code review',
    })

    vim.keymap.set('n', '<Leader>br', function()
        vim.ui.input(
            { prompt = 'Base branch for diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    helpers.run_slash_command('code_review', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buffer = args.buf,
        desc = 'Code review with base branch',
    })

    vim.keymap.set('n', '<Leader>cl', function()
        helpers.run_slash_command('changelog')
    end, {
        buffer = args.buf,
        desc = 'Generate changelog since last release',
    })
end

-- Filetype mapping registration
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

-- Global mappings
local function setup_global_mappings()
    vim.keymap.set('n', '<Leader>cg', helpers.focus_or_toggle_chat, {
        desc = 'Toggle CodeCompanion chat',
    })

    vim.keymap.set({ 'n', 'v' }, '<Leader>cr', run_command_line, {
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

    vim.keymap.set('n', '<Leader>ac', add_current_buffer_context, {
        desc = 'Add current file to CodeCompanion',
    })
end

-- Public setup
function M.setup()
    setup_filetype_mappings()
    setup_global_mappings()
end

return M
