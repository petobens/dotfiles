local M = {}

local state = {
    dashboard = nil,
    installed = {},
    log = nil,
    plugins = {},
    pending_builds = {},
    progress = nil,
    removed = {},
    startup_ms = nil,
    sync = { status = 'idle', updates = {} },
}

local function startup_ms()
    local started = vim.g.nvim_start_time
    return state.startup_ms or (started and (vim.uv.hrtime() - started) / 1e6) or 0
end

local function notify_error(action, name, err)
    vim.notify(
        ('Package manager failed to %s %s:\n%s'):format(action, name, err),
        vim.log.levels.ERROR
    )
end

local function record_sync_error(message)
    state.sync.error = state.sync.error and (state.sync.error .. '\n\n' .. message)
        or message
end

-- Plugin lifecycle
local function metadata(plugin)
    return plugin.spec.data or {}
end

local function list(value)
    return type(value) == 'table' and value or { value }
end

local function configure(plugin)
    local configs = metadata(plugin).config
    if plugin.configured or not configs then
        return
    end

    configs = list(configs)
    local ok, err = pcall(function()
        for _, config in ipairs(configs) do
            require('plugin-config.' .. config)
        end
    end)
    if ok then
        plugin.configured = true
    else
        notify_error('configure', plugin.spec.name, err)
    end
end

local function load(plugin, defer_scripts)
    if plugin.loaded then
        return
    end

    local ok, err = pcall(function()
        vim.cmd.packadd({
            plugin.spec.name,
            bang = defer_scripts,
            magic = { file = false },
        })

        -- Startup sources plugin/ and after/plugin/ later. Deferred loaders
        -- need both directories sourced immediately.
        if not defer_scripts then
            local after = vim.fs.joinpath(plugin.path, 'after', 'plugin')
            if vim.uv.fs_stat(after) then
                local scripts = vim.iter(vim.fs.dir(after, { depth = math.huge }))
                    :filter(function(name, kind)
                        return kind == 'file'
                            and (name:match('%.lua$') or name:match('%.vim$'))
                    end)
                    :map(function(name)
                        return vim.fs.joinpath(after, name)
                    end)
                    :totable()
                table.sort(scripts)
                for _, script in ipairs(scripts) do
                    vim.cmd.source({ args = { script }, magic = { file = false } })
                end
            end
        end
    end)
    if not ok then
        notify_error('load', plugin.spec.name, err)
        return
    end
    plugin.loaded = true
end

local function clear_deferred_loaders(plugin)
    local loaders = plugin.loaders
    if not loaders then
        return
    end

    for _, autocmd in ipairs(loaders.autocmds) do
        pcall(vim.api.nvim_del_autocmd, autocmd)
    end
    for _, command in ipairs(loaders.commands) do
        pcall(vim.api.nvim_del_user_command, command)
    end
    for _, key in ipairs(loaders.keys) do
        pcall(vim.keymap.del, 'n', key)
    end
    plugin.loaders = nil
end

local function activate(plugin)
    clear_deferred_loaders(plugin)
    load(plugin)
    if plugin.loaded then
        configure(plugin)
    end
end

local function autocmd_group_ids(event)
    local group_ids = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
        if autocmd.group then
            group_ids[autocmd.group] = true
        end
    end
    return group_ids
end

local function replay_new_autocmds(event, previous_group_ids)
    local replayed_groups = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event.event })) do
        local group = autocmd.group
        if group and not previous_group_ids[group] and not replayed_groups[group] then
            replayed_groups[group] = true
            vim.api.nvim_exec_autocmds(event.event, {
                buf = event.buf,
                data = event.data,
                group = group,
                modeline = false,
            })
        end
    end
end

local function setup_deferred_load(plugin)
    local data = metadata(plugin)
    plugin.loaders = { autocmds = {}, commands = {}, keys = {} }
    if data.event then
        local autocmd = vim.api.nvim_create_autocmd(data.event, {
            once = true,
            pattern = data.pattern,
            desc = 'Load ' .. plugin.spec.name,
            callback = function(event)
                local group_ids = autocmd_group_ids(event.event)
                activate(plugin)
                -- Handlers registered during an event miss its current dispatch.
                -- Replay only new groups so existing handlers do not run twice.
                replay_new_autocmds(event, group_ids)
            end,
        })
        plugin.loaders.autocmds[#plugin.loaders.autocmds + 1] = autocmd
    end

    for _, name in ipairs(data.cmd and list(data.cmd) or {}) do
        plugin.loaders.commands[#plugin.loaders.commands + 1] = name
        vim.api.nvim_create_user_command(name, function(args)
            activate(plugin)
            local command = {
                args = args.fargs,
                bang = args.bang,
                cmd = args.name,
                mods = args.smods,
            }
            if args.range > 0 then
                command.range = { args.line1, args.line2 }
            end
            vim.api.nvim_cmd(command, {})
        end, {
            bang = true,
            complete = 'file',
            desc = 'Load ' .. plugin.spec.name,
            nargs = '*',
            range = true,
        })
    end

    -- Replace loader mappings with the configured mappings, then replay the key
    for _, lhs in ipairs(data.keys or {}) do
        local key = lhs
        plugin.loaders.keys[#plugin.loaders.keys + 1] = key
        vim.keymap.set('n', key, function()
            activate(plugin)
            local keys =
                vim.api.nvim_replace_termcodes('<Ignore>' .. key, true, true, true)
            vim.api.nvim_feedkeys(keys, 'i', false)
        end, { desc = 'Load ' .. plugin.spec.name })
    end
end

-- Build hooks and cleanup
local function run_build(spec, path)
    local build = spec.data and spec.data.build
    if not build then
        return true
    end

    local ok, err = xpcall(function()
        if type(build) == 'function' then
            -- Function hooks may require modules from the package being built
            vim.cmd.packadd({ spec.name, bang = true })
            build()
        elseif vim.startswith(build, ':') then
            vim.cmd.packadd(spec.name)
            vim.cmd[build:sub(2)]()
        else
            local result = vim.system(vim.split(build, ' ', { trimempty = true }), {
                cwd = path,
                text = true,
            }):wait()
            assert(result.code == 0, result.stderr)
        end
    end, debug.traceback)
    if not ok then
        notify_error('build', spec.name, err)
    end
    return ok, err
end

local function remove_undeclared()
    local inactive = vim.iter(vim.pack.get(nil, { info = false }))
        :filter(function(plugin)
            return not plugin.active
        end)
        :map(function(plugin)
            return plugin.spec.name
        end)
        :totable()

    if #inactive > 0 then
        vim.pack.del(inactive)
    end
end

-- Package and Git data
local function git(path, args)
    local command = { 'git', '-C', path }
    vim.list_extend(command, args)
    local result = vim.system(command, { text = true }):wait()
    return result.code == 0 and vim.trim(result.stdout) or ''
end

local function packages()
    local result = vim.pack.get(nil, { info = false })
    table.sort(result, function(a, b)
        local left = a.spec.name:lower()
        local right = b.spec.name:lower()
        return left == right and a.spec.name < b.spec.name or left < right
    end)
    return result
end

local function is_loaded(plugin)
    return vim.iter(state.plugins):any(function(item)
        return item.spec.name == plugin.spec.name and item.loaded
    end)
end

local function commits(plugin, range, since)
    local args = {
        'log',
        '--no-merges',
        '--pretty=format:%H%x1f%s%x1f%cr',
    }
    if since then
        args[#args + 1] = '--since=' .. since
    end
    if range then
        args[#args + 1] = range
    end

    return vim.iter(vim.split(git(plugin.path, args), '\n', { trimempty = true }))
        :map(function(line)
            local fields = vim.split(line, '\31', { plain = true })
            return { hash = fields[1], message = fields[2], age = fields[3] }
        end)
        :totable()
end

local function recent_updates(all)
    if state.log then
        return state.log
    end

    state.log = {}
    for _, plugin in ipairs(all) do
        local history = commits(plugin, nil, '2 days ago')
        if #history > 0 then
            state.log[#state.log + 1] = { plugin = plugin, commits = history }
        end
    end
    return state.log
end

-- Synchronization
local function revision(path)
    return git(path, { 'rev-parse', 'HEAD' })
end

local function capture_pack_progress(callback)
    local echo = vim.api.nvim_echo
    local function capture(chunks, history, opts)
        if opts and opts.kind == 'progress' and opts.source == 'vim.pack' then
            state.progress = {
                percent = opts.percent,
                status = opts.status,
                text = chunks,
            }
            if state.dashboard then
                state.dashboard.render('sync')
            end
            return opts.id or 1
        end
        return opts and echo(chunks, history, opts) or echo(chunks, history)
    end

    -- vim.pack exposes progress only as structured nvim_echo calls, not through
    -- a callback. Intercept them during updates so they render in the dashboard.
    vim.api.nvim_echo = capture
    local ok, err = pcall(callback)
    vim.schedule(function()
        if vim.api.nvim_echo == capture then
            vim.api.nvim_echo = echo
        end
    end)
    return ok, err
end

local function start_sync()
    if state.sync.status == 'running' then
        return
    end

    local before = {}
    for _, plugin in ipairs(packages()) do
        before[plugin.spec.name] = revision(plugin.path)
    end
    state.sync = {
        before = before,
        status = 'running',
        updates = {},
    }
    state.progress = { percent = 0, status = 'running', text = 'Starting sync' }
    if state.dashboard then
        state.dashboard.render('sync')
    end

    local log_path = vim.fs.joinpath(vim.fn.stdpath('log'), 'nvim-pack.log')
    local log_start = vim.uv.fs_stat(log_path) and #vim.fn.readfile(log_path) or 0
    local ok, err = capture_pack_progress(function()
        vim.pack.update(nil, { force = true })
    end)
    if vim.uv.fs_stat(log_path) then
        local error_lines = {}
        local in_errors = false
        for index, line in ipairs(vim.fn.readfile(log_path)) do
            if index > log_start then
                if vim.startswith(line, '# Error ') then
                    in_errors = true
                elseif in_errors and vim.startswith(line, '# ') then
                    break
                elseif in_errors then
                    error_lines[#error_lines + 1] = line
                end
            end
        end
        local update_error = vim.trim(table.concat(error_lines, '\n'))
        if update_error ~= '' then
            record_sync_error(update_error)
        end
    end
    if not ok then
        record_sync_error(tostring(err))
    end
    state.sync.status = state.sync.error and 'error' or 'done'
    state.log = nil
    if state.dashboard then
        state.dashboard.render('sync')
    end
end

local function schedule_sync(force)
    if vim.list_contains({ 'running', 'scheduled' }, state.sync.status) then
        return
    end
    if not force and state.sync.status ~= 'idle' then
        return
    end
    state.sync.status = 'scheduled'
    vim.schedule(function()
        if state.sync.status == 'scheduled' then
            start_sync()
        end
    end)
end

-- Public setup
function M.setup(specs)
    vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        desc = 'Finish package manager startup',
        callback = function()
            state.startup_ms = startup_ms()
            local packages_changed = next(state.installed) ~= nil or #state.removed > 0
            if packages_changed and #vim.api.nvim_list_uis() > 0 then
                vim.schedule(require('pack.dashboard').open)
            end
        end,
    })
    vim.api.nvim_create_autocmd('PackChanged', {
        desc = 'Run package build hooks',
        callback = function(event)
            local plugin = {
                path = event.data.path,
                spec = event.data.spec,
            }
            if state.sync.status == 'running' then
                if event.data.kind == 'update' then
                    local old = state.sync.before[event.data.spec.name]
                    local new = revision(event.data.path)
                    state.sync.updates[#state.sync.updates + 1] = {
                        commits = commits(plugin, old .. '..' .. new),
                        from = old,
                        kind = 'update',
                        plugin = plugin,
                        to = new,
                    }
                elseif event.data.kind == 'delete' then
                    state.sync.updates[#state.sync.updates + 1] = {
                        kind = 'delete',
                        plugin = plugin,
                    }
                end
            end
            if event.data.kind == 'delete' then
                state.installed[event.data.spec.name] = nil
                state.removed[#state.removed + 1] = plugin
                return
            end
            if event.data.kind == 'install' then
                state.installed[event.data.spec.name] = true
                state.pending_builds[event.data.spec.name] = event.data.path
            else
                local built, build_error = run_build(event.data.spec, event.data.path)
                if not built and state.sync.status == 'running' then
                    record_sync_error(
                        ('%s build:\n%s'):format(event.data.spec.name, build_error)
                    )
                end
            end
        end,
    })

    -- An add can partially succeed, so finalize returned plugins even on error
    local ok, err = pcall(vim.pack.add, specs, {
        confirm = false,
        load = function(plugin)
            state.plugins[#state.plugins + 1] = plugin
        end,
    })
    if not ok then
        notify_error('install', 'plugins', err)
    else
        local cleaned, clean_error = pcall(remove_undeclared)
        if not cleaned then
            notify_error('uninstall', 'plugins', clean_error)
        end
    end

    -- Register deferred loaders and load non-deferred packages
    for _, plugin in ipairs(state.plugins) do
        local data = metadata(plugin)
        if data.event or data.cmd or data.keys then
            setup_deferred_load(plugin)
        else
            load(plugin, vim.v.vim_did_init == 0)
        end
    end

    -- Run build hooks, then configure non-deferred packages
    for _, plugin in ipairs(state.plugins) do
        local build_path = state.pending_builds[plugin.spec.name]
        if build_path then
            run_build(plugin.spec, build_path)
            state.pending_builds[plugin.spec.name] = nil
        end
        local data = metadata(plugin)
        if not data.event and not data.cmd and not data.keys then
            activate(plugin)
        end
    end
end

M.is_loaded = is_loaded
M.metadata = metadata
M.notify_error = notify_error
M.packages = packages
M.recent_updates = recent_updates
M.schedule_sync = schedule_sync
M.state = state
M.startup_ms = startup_ms

return M
