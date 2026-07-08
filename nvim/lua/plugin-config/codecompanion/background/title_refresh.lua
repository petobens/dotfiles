local native = require('codecompanion.interactions.background.builtin.chat_make_title')
local utils = require('codecompanion.utils')

local M = {}

local REFRESH_EVERY_N_TURNS = 3
local baseline_turns = {}
local pending = {}

function M.request(background, chat)
    local bufnr = chat.bufnr
    local completed_turns = (chat.cycle or 1) - 1
    local has_title = chat.title and chat.title ~= ''

    if pending[bufnr] then
        return
    end

    if baseline_turns[bufnr] == nil then
        baseline_turns[bufnr] = completed_turns
        if has_title then
            return
        end
    end

    local turns_since_title = completed_turns - baseline_turns[bufnr]
    local should_refresh = has_title
        and turns_since_title > 0
        and turns_since_title % REFRESH_EVERY_N_TURNS == 0

    if has_title and not should_refresh then
        return
    end

    local title_before = chat.title or ''
    local cycle_before = chat.cycle
    pending[bufnr] = true
    background:ask({
        {
            role = 'system',
            content = table.concat({
                'Write a specific title of 6 to 8 words for this chat that captures',
                'the durable implementation or decision.',
                'Prefer the final outcome over the initial request when the topic',
                'changes.',
                'Do not title the chat after a tiny final tweak unless that was',
                'the main result.',
                'Reply with only the title.',
            }, ' '),
        },
        {
            role = 'user',
            content = 'Chat transcript:\n\n' .. native.format_messages(chat.messages),
        },
    }, {
        method = 'async',
        silent = true,
        on_done = function(result)
            pending[bufnr] = nil
            if chat.cycle ~= cycle_before then
                return
            end
            if (chat.title or '') ~= title_before then
                return
            end
            local title = native.on_done(result)
            if not title then
                return
            end
            chat:set_title(title)
            baseline_turns[bufnr] = completed_turns
            utils.fire('BackgroundTitleSet', {
                bufnr = chat.bufnr,
                id = chat.id,
                title = title,
            })
        end,
        on_error = function()
            pending[bufnr] = nil
        end,
    })
end

return M
