local M = {}

local function conversation(source)
    return vim.iter(source or {})
        :filter(function(message)
            return type(message.content) == 'string'
                and (message.role == 'user' or message.role == 'llm')
        end)
        :totable()
end

function M.clone_chat(chat)
    -- Restored ACP sessions leave chat.messages with only a system prompt, so
    -- fall back to the structured messages the picker retained on restore
    local messages = conversation(chat.messages)
    if #messages == 0 then
        messages = conversation(chat._acp_restored_messages)
    end

    if #messages == 0 then
        return vim.notify('No messages to clone', vim.log.levels.WARN)
    end

    vim.ui.input({ prompt = 'Last N messages (blank for all): ' }, function(input)
        local count = tonumber(input)
        if input == nil or (input ~= '' and (not count or count < 1)) then
            return
        end
        messages =
            vim.list_slice(messages, math.max(1, #messages - (count or #messages) + 1))

        local change_adapter =
            require('codecompanion.interactions.chat.keymaps.change_adapter')
        vim.ui.select(
            change_adapter.get_adapters_list(chat.adapter.name),
            { prompt = 'Clone adapter: ' },
            function(adapter)
                if not adapter then
                    return
                end

                local cloned_messages = vim.deepcopy(messages)
                local resolved = require('codecompanion.adapters').resolve(adapter)
                if resolved.type == 'acp' then
                    for _, message in ipairs(cloned_messages) do
                        if message.role == 'user' then
                            message._meta = message._meta or {}
                            message._meta.sent = true
                        end
                    end
                    table.insert(cloned_messages, {
                        role = 'user',
                        content = 'Conversation cloned from another chat:\n\n'
                            .. vim.iter(messages)
                                :map(function(message)
                                    return message.role .. ': ' .. message.content
                                end)
                                :join('\n\n'),
                        opts = { visible = false },
                        _meta = { sent = false },
                    })
                end
                table.insert(cloned_messages, { role = 'user', content = '' })

                require('codecompanion.interactions.chat').new({
                    adapter = adapter,
                    messages = cloned_messages,
                    stop_context_insertion = true,
                    title = 'Clone of: ' .. (chat.title or 'Chat'),
                })
            end
        )
    end)
end

return M
