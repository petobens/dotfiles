local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local devicons = require('nvim-web-devicons')
local helpers = require('plugin-config.codecompanion.helpers')
local prompt_library = require('plugin-config.codecompanion.prompt_library')

local M = {}

-- Chat role label formatter for the chat UI
function M.llm_role(adapter)
    local current_system_role_prompt = helpers.get_current_system_role_prompt()
    local system_role = prompt_library.SYSTEM_ROLE

    for name, prompt in pairs(config.prompt_library or {}) do
        local prompts = prompt and prompt.prompts
        if type(prompts) == 'table' then
            local first = prompts[1]
            if first and type(first.content) == 'string' then
                if first.content == current_system_role_prompt then
                    system_role = name
                    break
                end
            end
        end
    end

    return string.format(
        '%s (%s) | %s |  %d |  %s',
        adapter.formatted_name,
        adapter.schema.model.default,
        system_role,
        helpers.get_chat_cycles(),
        helpers.get_context_usage(adapter)
    )
end

-- Spinner helpers
local spinner = {
    ns_id = vim.api.nvim_create_namespace('codecompanion_spinner'),
    states = {
        '⢎ ',
        '⠎⠁',
        '⠊⠑',
        '⠈⠱',
        ' ⡱',
        '⢀⡰',
        '⢄⡠',
        '⢆⡀',
    },
    bufnr = nil,
    line = nil,
    timer = nil,
    index = 1,
}

local function clear_spinner()
    if spinner.bufnr and vim.api.nvim_buf_is_valid(spinner.bufnr) then
        vim.api.nvim_buf_clear_namespace(spinner.bufnr, spinner.ns_id, 0, -1)
    end

    spinner.bufnr = nil
    spinner.line = nil
    spinner.index = 1

    if spinner.timer then
        spinner.timer:stop()
        spinner.timer:close()
        spinner.timer = nil
    end
end

local function update_spinner()
    if spinner.bufnr and spinner.line and vim.api.nvim_buf_is_valid(spinner.bufnr) then
        vim.api.nvim_buf_clear_namespace(
            spinner.bufnr,
            spinner.ns_id,
            spinner.line,
            spinner.line + 1
        )
        vim.api.nvim_buf_set_extmark(spinner.bufnr, spinner.ns_id, spinner.line, 0, {
            virt_text = {
                { ' Working ' .. spinner.states[spinner.index], 'Comment' },
            },
            virt_text_pos = 'eol',
        })
        spinner.index = spinner.index % #spinner.states + 1
    end
end

function M.setup()
    -- Icons
    devicons.set_icon({
        codecompanion = { icon = ' ' },
    })
    devicons.set_icon_by_filetype({ codecompanion = 'codecompanion' })

    -- Window titles
    vim.api.nvim_create_autocmd('User', {
        pattern = {
            'CodeCompanionChatCreated',
            'CodeCompanionChatOpened',
            'CodeCompanionHistoryTitleSet',
        },
        desc = 'Set CodeCompanion chat window title after chat events',
        callback = function(e)
            vim.defer_fn(function()
                helpers.set_chat_win_title(e)
            end, 1)
        end,
    })

    -- Spinner lifecycle
    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionRequestStarted',
        desc = 'Start CodeCompanion spinner on request start',
        callback = function()
            clear_spinner()

            spinner.bufnr = vim.api.nvim_get_current_buf()
            spinner.line = vim.api.nvim_win_get_cursor(0)[1] - 1
            spinner.timer = vim.uv.new_timer()
            spinner.timer:start(0, 120, vim.schedule_wrap(update_spinner))
        end,
    })

    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionRequestFinished',
        desc = 'Clear CodeCompanion spinner on request finish',
        callback = function()
            vim.defer_fn(clear_spinner, 50)
        end,
    })

    -- Diff behavior
    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionDiffAttached',
        desc = 'Ensure diffs start in normal mode and preserve window order',
        callback = function()
            vim.defer_fn(function()
                vim.cmd.stopinsert()
                if vim.api.nvim_win_get_config(0).relative ~= '' then
                    return
                end
                vim.cmd.wincmd('x')
                vim.cmd.wincmd('p')
            end, 1)
        end,
    })

    -- History extension
    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionChatCreated',
        desc = 'Restore CodeCompanion history metadata',
        callback = function(args)
            vim.schedule(function()
                local history = codecompanion.extensions.history
                local chat = codecompanion.buf_get_chat(args.data.bufnr)
                local save_id = chat.opts.save_id
                local saved_chat = save_id and history.load_chat(save_id)
                if not saved_chat then
                    return
                end

                _G.codecompanion_chat_metadata = _G.codecompanion_chat_metadata or {}
                _G.codecompanion_chat_metadata[chat.bufnr] = vim.tbl_deep_extend(
                    'force',
                    _G.codecompanion_chat_metadata[chat.bufnr] or {},
                    {
                        cycles = saved_chat.cycle,
                        tokens = history.get_chats()[save_id].token_estimate,
                    }
                )

                vim.cmd.redrawstatus()
            end)
        end,
    })
end

return M
