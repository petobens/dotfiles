local M = {}

local items = {}
local manager = require('pack.manager')
local namespace = vim.api.nvim_create_namespace('nvim-pack')
local state = manager.state

local function list(value)
    return type(value) == 'table' and value or { value }
end

-- Window
local function float_config()
    local width = math.min(130, math.max(1, vim.o.columns - 4))
    local height = math.max(1, vim.o.lines - 5)
    return {
        relative = 'editor',
        row = 1,
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' Packages ',
        title_pos = 'center',
        zindex = 50,
    }
end

local function setup_float(buffer, window)
    vim.wo[window].colorcolumn = ''
    vim.wo[window].foldenable = false
    vim.wo[window].spell = false
    vim.wo[window].winhighlight = 'Normal:NormalFloat,EndOfBuffer:NormalFloat'
    vim.wo[window].wrap = true
    vim.api.nvim_create_autocmd('VimResized', {
        buffer = buffer,
        desc = 'Resize native package manager',
        callback = function()
            if vim.api.nvim_win_is_valid(window) then
                vim.api.nvim_win_set_config(window, float_config())
            end
        end,
    })
end

-- Rendering
local function deferred_triggers(plugin)
    local data = manager.metadata(plugin)
    local triggers = {}
    if data.event then
        local event = table.concat(list(data.event), ', ')
        if data.pattern then
            event = event .. ' ' .. table.concat(list(data.pattern), ', ')
        end
        triggers[#triggers + 1] = { icon = '', text = event, group = 'Special' }
    end
    if data.cmd then
        triggers[#triggers + 1] = {
            icon = '',
            text = ':' .. table.concat(list(data.cmd), ', :'),
            group = 'Statement',
        }
    end
    if data.keys then
        triggers[#triggers + 1] = {
            icon = '',
            text = table.concat(data.keys, ', '),
            group = 'String',
        }
    end
    return triggers
end

local function progress_text(progress)
    if type(progress.text) ~= 'table' then
        return progress.text or ''
    end
    return vim.iter(progress.text)
        :map(function(chunk)
            return chunk[1]
        end)
        :join('')
end

local function add_highlight(highlights, line, group, start_col, end_col)
    highlights[#highlights + 1] = { group, line, start_col, end_col }
end

local function highlight_commit(highlights, line, text, message, age)
    add_highlight(highlights, line, 'Identifier', 6, 13)
    local dimmed = vim.iter({ 'bot', 'build', 'ci', 'chore', 'doc', 'style', 'test' })
        :any(function(prefix)
            return vim.startswith(message, prefix)
        end)
    if dimmed then
        add_highlight(highlights, line, 'NonText', 15, age and #text - #age - 2 or -1)
    end
    local prefix = text:match('^%s+%x+%s+([^:]+:)')
    if prefix then
        local start_col = text:find(prefix, 1, true) - 1
        add_highlight(
            highlights,
            line,
            dimmed and 'Bold' or 'Title',
            start_col,
            start_col + #prefix
        )
    end
    local start = 1
    while true do
        local first, last = text:find('#%d+', start)
        if not first then
            break
        end
        add_highlight(highlights, line, 'Number', first - 1, last)
        start = last + 1
    end
    if age then
        add_highlight(highlights, line, 'Comment', #text - #age - 2, -1)
    end
end

local function render_dashboard(buffer, view)
    local all = manager.packages()
    local active = vim.iter(all)
        :filter(function(plugin)
            return plugin.active
        end)
        :totable()
    local deferred = vim.iter(active)
        :filter(function(plugin)
            return #deferred_triggers(plugin) > 0
        end)
        :fold(0, function(count)
            return count + 1
        end)
    local lines = {
        'Home (H)   Log (L)   Sync (S)',
        '',
        ('Total: %d plugins (%d deferred)   Startup: %.2f ms'):format(
            #active,
            deferred,
            manager.startup_ms()
        ),
        '',
    }
    local highlights = {}
    items = {}

    local function add(text, item)
        local line = #lines
        lines[#lines + 1] = text
        items[line + 1] = item
        return line
    end

    local function add_heading(title, count)
        local line = add(count and ('%s (%d)'):format(title, count) or title)
        add_highlight(highlights, line, 'Bold', 0, #title)
        if count then
            add_highlight(highlights, line, 'Comment', #title + 1, -1)
        end
    end

    local function add_plugin(plugin, item, suffix)
        local line = add(('  ● %s%s'):format(plugin.spec.name, suffix or ''), item)
        add_highlight(highlights, line, '@punctuation.special', 2, 5)
    end

    local function add_commits(plugin, history, show_age)
        for _, commit in ipairs(history or {}) do
            commit.plugin = plugin
            local age = show_age and (' (' .. commit.age .. ')') or ''
            local text = ('      %s  %s%s'):format(
                commit.hash:sub(1, 7),
                commit.message,
                age
            )
            local line = add(text, commit)
            highlight_commit(
                highlights,
                line,
                text,
                commit.message,
                show_age and commit.age
            )
        end
    end

    local function add_package(plugin)
        local hash = plugin.rev:sub(1, 7)
        local text = ('  ● %-32s %s'):format(plugin.spec.name, hash)
        local hash_start = #text - #hash
        local plugin_highlights = {}
        for _, trigger in ipairs(deferred_triggers(plugin)) do
            text = text .. '  '
            local start_col = #text
            text = text .. trigger.icon .. ' ' .. trigger.text
            plugin_highlights[#plugin_highlights + 1] = {
                end_col = #text,
                group = trigger.group,
                start_col = start_col,
            }
        end
        local line = add(text)
        add_highlight(highlights, line, '@punctuation.special', 2, 5)
        add_highlight(highlights, line, 'Identifier', hash_start, hash_start + #hash)
        for _, highlight in ipairs(plugin_highlights) do
            add_highlight(
                highlights,
                line,
                highlight.group,
                highlight.start_col,
                highlight.end_col
            )
        end
    end

    local function add_package_section(title, entries)
        if #entries == 0 then
            return
        end
        add_heading(title, #entries)
        for _, plugin in ipairs(entries) do
            add_package(plugin)
        end
        lines[#lines + 1] = ''
    end

    if view == 'home' then
        local installed = vim.iter(active)
            :filter(function(plugin)
                return state.installed[plugin.spec.name]
            end)
            :totable()
        local loaded = vim.iter(active)
            :filter(function(plugin)
                return not state.installed[plugin.spec.name] and manager.is_loaded(plugin)
            end)
            :totable()
        local deferred_packages = vim.iter(active)
            :filter(function(plugin)
                return not state.installed[plugin.spec.name]
                    and not manager.is_loaded(plugin)
                    and #deferred_triggers(plugin) > 0
            end)
            :totable()
        local not_loaded = vim.iter(active)
            :filter(function(plugin)
                return not state.installed[plugin.spec.name]
                    and not manager.is_loaded(plugin)
                    and #deferred_triggers(plugin) == 0
            end)
            :totable()

        add_package_section('Installed', installed)
        if #state.removed > 0 then
            add_heading('Uninstalled', #state.removed)
            for _, plugin in ipairs(state.removed) do
                add_plugin(plugin, plugin)
            end
            lines[#lines + 1] = ''
        end
        add_package_section('Loaded', loaded)
        add_package_section('Deferred', deferred_packages)
        add_package_section('Not Loaded', not_loaded)
    elseif view == 'log' then
        local updates = manager.recent_updates(all)
        add_heading('Updates in the last 2 days', #updates)
        if #updates == 0 then
            lines[#lines + 1] = '  No recent updates'
        end
        for _, entry in ipairs(updates) do
            add_plugin(entry.plugin, entry.plugin)
            add_commits(entry.plugin, entry.commits, true)
            lines[#lines + 1] = ''
        end
    else
        local sync_state = state.sync
        if sync_state.status == 'running' then
            add_heading('Sync')
            local progress = state.progress or {}
            local percent = progress.percent or 0
            local width = math.min(40, math.max(10, vim.o.columns - 15))
            local done = math.floor(width * percent / 100)
            local complete = string.rep('━', done)
            local bar = complete .. string.rep('─', width - done)
            local line = add(('  %s %3d%%'):format(bar, percent))
            add_highlight(highlights, line, 'Constant', 2, 2 + #complete)
            add_highlight(highlights, line, 'LineNr', 2 + #complete, 2 + #bar)
            local detail = progress_text(progress)
            if detail ~= '' then
                lines[#lines + 1] = '  ' .. detail
            end
        elseif sync_state.status == 'error' then
            add_heading('Sync Failed')
            local message = sync_state.error
                or progress_text(state.progress or {})
                or 'Unknown error'
            for error_line in message:gmatch('[^\n]+') do
                local line = add('  ' .. error_line)
                add_highlight(highlights, line, 'ErrorMsg', 2, -1)
            end
            lines[#lines + 1] = '  Press R to sync again'
        elseif #sync_state.updates == 0 then
            add_heading('Sync')
            lines[#lines + 1] = sync_state.status == 'done'
                    and '  No changes (press R to sync again)'
                or '  Press S to sync packages'
        else
            add_heading('Updated', #sync_state.updates)
            for _, update in ipairs(sync_state.updates) do
                local suffix = update.kind == 'delete' and ' removed' or ''
                add_plugin(update.plugin, update, suffix)
                add_commits(update.plugin, update.commits)
            end
            lines[#lines + 1] = ''
            lines[#lines + 1] = '  Press R to sync again'
        end
    end

    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
    vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
    local function set_highlight(group, line, start_col, end_col)
        vim.api.nvim_buf_set_extmark(buffer, namespace, line, start_col, {
            end_col = end_col == -1 and #lines[line + 1] or end_col,
            hl_group = group,
        })
    end
    local startup = lines[3]:find('Startup:', 1, true) - 1
    set_highlight('Bold', 2, 0, 6)
    set_highlight('Comment', 2, 7, startup)
    set_highlight('Bold', 2, startup, startup + 8)
    set_highlight('Comment', 2, startup + 9, -1)

    local tabs = {
        home = { { 0, 8, 'Visual' }, { 11, 18, 'CursorLine' }, { 21, 29, 'CursorLine' } },
        log = { { 0, 8, 'CursorLine' }, { 11, 18, 'Visual' }, { 21, 29, 'CursorLine' } },
        sync = { { 0, 8, 'CursorLine' }, { 11, 18, 'CursorLine' }, { 21, 29, 'Visual' } },
    }
    for _, tab in ipairs(tabs[view]) do
        set_highlight(tab[3], 0, tab[1], tab[2])
    end
    for _, shortcut in ipairs({ { 5, 8 }, { 15, 18 }, { 26, 29 } }) do
        set_highlight('@punctuation.special', 0, shortcut[1], shortcut[2])
    end
    for _, highlight in ipairs(highlights) do
        set_highlight(unpack(highlight))
    end
end

-- Diff actions
local function in_repo(plugin, action, callback)
    local cwd = vim.fn.getcwd(0)
    vim.cmd.lcd({ args = { plugin.path } })
    local ok, err = pcall(callback)
    vim.cmd.lcd({ args = { cwd } })
    if not ok then
        manager.notify_error(action, plugin.spec.name, err)
    end
    return ok
end

local function open_item_url()
    local item = items[vim.api.nvim_win_get_cursor(0)[1]]
    local plugin = item and (item.plugin or item)
    local hash = item and (item.hash or item.to)
    if plugin and hash then
        in_repo(plugin, 'open in browser', function()
            vim.cmd.GBrowse({ args = { hash }, mods = { silent = true } })
        end)
    end
end

local function show_item_diff()
    local item = items[vim.api.nvim_win_get_cursor(0)[1]]
    local plugin = item and (item.plugin or item)
    if not plugin then
        return
    end

    if not item.hash and not (item.from and item.to) then
        return
    end

    local ok = in_repo(plugin, 'show diff for', function()
        if item.hash then
            vim.cmd.Gedit({ args = { item.hash } })
        else
            vim.cmd.Git(('++curwin --paginate diff %s..%s'):format(item.from, item.to))
        end
    end)
    if not ok then
        return
    end

    local dashboard = state.dashboard
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].buflisted = false
    vim.bo[buffer].bufhidden = 'wipe'
    vim.keymap.set('n', 'q', function()
        if vim.api.nvim_win_is_valid(dashboard.window) then
            vim.api.nvim_win_set_buf(dashboard.window, dashboard.buffer)
        end
    end, { buffer = buffer, desc = 'Return to native package manager' })
end

-- Lifecycle
local function open_dashboard(initial_view)
    local current = state.dashboard
    if
        current
        and vim.api.nvim_buf_is_valid(current.buffer)
        and vim.api.nvim_win_is_valid(current.window)
    then
        vim.api.nvim_win_set_buf(current.window, current.buffer)
        vim.api.nvim_set_current_win(current.window)
        current.render(initial_view)
        if initial_view == 'sync' then
            manager.schedule_sync()
        end
        return
    end

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, 'nvim-pack://dashboard/' .. buffer)
    vim.bo[buffer].bufhidden = 'hide'
    vim.bo[buffer].buftype = 'nofile'
    vim.bo[buffer].filetype = 'nvim-pack'
    vim.bo[buffer].swapfile = false
    local window = vim.api.nvim_open_win(buffer, true, float_config())
    local dashboard = { buffer = buffer, window = window }
    state.dashboard = dashboard
    setup_float(buffer, window)

    local function cleanup()
        if vim.api.nvim_buf_is_valid(buffer) then
            vim.api.nvim_buf_delete(buffer, { force = true })
        end
        if state.dashboard == dashboard then
            state.dashboard = nil
        end
    end

    vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(window),
        once = true,
        desc = 'Clean up native package dashboard',
        callback = function()
            vim.schedule(cleanup)
        end,
    })

    local view = initial_view
    local function render(next_view)
        view = next_view or view
        render_dashboard(buffer, view)
    end
    dashboard.render = render
    render()

    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(window, true)
        cleanup()
    end, {
        buffer = buffer,
        desc = 'Close native package manager',
    })
    vim.keymap.set('n', 'S', function()
        render('sync')
        manager.schedule_sync()
    end, {
        buffer = buffer,
        desc = 'Sync native packages',
    })
    vim.keymap.set('n', 'R', function()
        render('sync')
        manager.schedule_sync(true)
    end, {
        buffer = buffer,
        desc = 'Resync native packages',
    })
    vim.keymap.set('n', 'H', function()
        render('home')
    end, { buffer = buffer, desc = 'Show native package manager home' })
    vim.keymap.set('n', 'L', function()
        render('log')
    end, { buffer = buffer, desc = 'Show native package log' })
    vim.keymap.set('n', 'd', show_item_diff, {
        buffer = buffer,
        desc = 'Show native package diff',
    })
    vim.keymap.set('n', 'K', open_item_url, {
        buffer = buffer,
        desc = 'Open native package change on GitHub',
    })

    if initial_view == 'sync' then
        manager.schedule_sync()
    end
end

function M.open()
    open_dashboard('home')
end

function M.log()
    open_dashboard('log')
end

function M.sync()
    open_dashboard('sync')
end

return M
