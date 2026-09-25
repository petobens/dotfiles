local M = {}

local tmux_data = setmetatable({}, { __mode = 'k' })

-- Helpers
local function add_tmux_pane_context_incremental(chat, target)
    if not vim.env.TMUX then
        vim.notify('Not in a tmux session', vim.log.levels.ERROR)
        return
    end

    target = vim.trim(target or '')
    if target == '' or not target:match('^%d+%.%d+$') then
        vim.notify('Invalid target, use window.pane (e.g. 2.1)', vim.log.levels.ERROR)
        return
    end

    local result = vim.system({
        'tmux',
        'capture-pane',
        '-p',
        '-S',
        '-3000',
        '-E',
        '-',
        '-t',
        target,
    }, { text = true }):wait()

    local out = (result.stdout or ''):gsub('\n+$', '')
    if result.code ~= 0 or vim.trim(out) == '' then
        vim.notify('No tmux output captured for target: ' .. target, vim.log.levels.WARN)
        return
    end

    local lines = vim.split(out, '\n', { plain = true })
    local captures = tmux_data[chat] or {}
    local prev = captures[target] or {}
    local overlap = 0
    -- Scrollback is bounded, so find shared lines instead of comparing counts
    for count = math.min(#prev, #lines), 1, -1 do
        local matches = true
        for i = 1, count do
            if prev[#prev - count + i] ~= lines[i] then
                matches = false
                break
            end
        end
        if matches then
            overlap = count
            break
        end
    end
    if overlap == #lines then
        vim.notify('No new tmux output for target: ' .. target)
        return
    end
    -- Include a little context; send the full snapshot if the pane was cleared
    local new_lines = {}
    for i = math.max(1, overlap - 2), #lines do
        table.insert(new_lines, lines[i])
    end

    captures[target] = lines
    tmux_data[chat] = captures

    chat:add_context({
        role = 'user',
        content = ('Latest tmux output (%s):\n\n%s'):format(
            target,
            table.concat(new_lines, '\n')
        ),
    }, 'terminal', ('<tmux>%s</tmux>'):format(target))
end

-- Slash commands
function M.tmux(chat)
    vim.ui.input({ prompt = 'tmux window.pane (default 1.2): ' }, function(target)
        if target == nil then
            return
        end
        target = vim.trim(target)
        if target == '' then
            target = '1.2'
        end
        add_tmux_pane_context_incremental(chat, target)
    end)
end

return M
