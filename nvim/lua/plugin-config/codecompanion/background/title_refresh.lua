local native = require('codecompanion.interactions.background.builtin.chat_make_title')
local tags = require('codecompanion.interactions.shared.tags')
local utils = require('codecompanion.utils')

local M = {}

local REFRESH_EVERY_N_TURNS = 3
local baseline_turns = setmetatable({}, { __mode = 'k' })
local pending = setmetatable({}, { __mode = 'k' })

-- Mirror upstream: request a JSON title so native.on_done decodes a field
-- instead of dumping the raw model reply as the title
local TITLE_SCHEMA = {
    name = 'title',
    schema = {
        type = 'object',
        properties = {
            title = {
                type = 'string',
                description = 'A specific title of 8 words or fewer capturing the chat',
            },
        },
        required = { 'title' },
        additionalProperties = false,
    },
    strict = true,
}

local function format_messages(messages)
    messages = vim.iter(messages or {})
        :map(function(message)
            -- Upstream strips images but not documents, whose base64
            -- payload overflows the title model's context
            if message._meta and message._meta.tag == tags.DOCUMENT then
                return vim.tbl_extend(
                    'force',
                    message,
                    { content = '[Document content omitted]' }
                )
            end
            return message
        end)
        :totable()

    return native.format_messages(messages)
end

function M.request(background, chat)
    local cycle = chat.cycle or 1
    local completed_turns = cycle - 1
    -- Supersede a request from an earlier turn that never completed (e.g. a
    -- cancelled turn), otherwise a stuck flag blocks all future titles
    if pending[chat] and pending[chat] >= cycle then
        return
    end

    -- A freshly loaded ACP session dispatches on_ready before
    -- _acp_session_loaded is set, with an empty chat.messages; skip without
    -- establishing the refresh baseline
    local transcript = format_messages(chat.messages)
    if vim.trim(transcript) == '' then
        return
    end

    if baseline_turns[chat] == nil then
        -- First time we see this chat. Only a restored session carries
        -- opts.title; a title an ACP agent pushes live (Codex/Claude, built
        -- from the combined prompt) lands in chat.title, which we ignore so it
        -- gets replaced by one generated from the real conversation
        baseline_turns[chat] = completed_turns - (chat._acp_session_loaded and 1 or 0)
        local restored = chat.opts and chat.opts.title and chat.opts.title ~= ''
        if restored then
            if (chat.title or '') ~= chat.opts.title then
                chat:set_title(chat.opts.title)
            end
            return
        end
    else
        -- Afterwards only refresh on the cadence, never on every turn
        local turns_since_title = completed_turns - baseline_turns[chat]
        if turns_since_title <= 0 or turns_since_title % REFRESH_EVERY_N_TURNS ~= 0 then
            return
        end
    end

    pending[chat] = cycle
    background:ask({
        {
            role = 'system',
            content = table.concat({
                'Write a specific title of 8 words or fewer for this chat that',
                'captures the durable implementation or decision.',
                'Keep a short user request unchanged when it already makes a',
                'good title.',
                'Prefer the final outcome over the initial request when the topic',
                'changes.',
                'Do not title the chat after a tiny final tweak unless that was',
                'the main result.',
                'Reply with only the title.',
            }, ' '),
        },
        {
            role = 'user',
            content = 'Chat transcript:\n\n' .. transcript,
        },
    }, {
        method = 'async',
        silent = true,
        structured_output = TITLE_SCHEMA,
        on_done = function(result)
            if pending[chat] ~= cycle then
                return
            end
            pending[chat] = nil
            local title = native.on_done(result)
            if not title then
                return
            end
            chat:set_title(title)
            baseline_turns[chat] = completed_turns
            -- Persist title so saved http chats show it instead of a timestamp
            local history = require('codecompanion').extensions.history
            if history then
                chat.opts.title = title
                pcall(history.save_chat, chat)
            end
            utils.fire('BackgroundTitleSet', {
                bufnr = chat.bufnr,
                id = chat.id,
                title = title,
            })
        end,
        on_error = function()
            if pending[chat] == cycle then
                pending[chat] = nil
            end
        end,
    })
end

return M
