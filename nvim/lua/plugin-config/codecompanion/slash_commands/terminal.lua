local M = {}

local tmux_data = {}

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

    local out = vim.trim(result.stdout or '')
    if result.code ~= 0 or out == '' then
        vim.notify('No tmux output captured for target: ' .. target, vim.log.levels.WARN)
        return
    end

    local lines = vim.split(out, '\n', { plain = true })
    local start_line = 1
    local prev = tmux_data[target]

    if prev and prev.lines then
        start_line = math.max(1, prev.lines - 3)
    end

    local new_lines = {}
    for i = start_line, #lines do
        table.insert(new_lines, lines[i])
    end

    tmux_data[target] = { lines = #lines }

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
        target = vim.trim(target or '')
        if target == '' then
            target = '1.2'
        end
        add_tmux_pane_context_incremental(chat, target)
    end)
end

return M
