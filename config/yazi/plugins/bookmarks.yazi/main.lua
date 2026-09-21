-- luacheck: globals ya cx

local get_cwd = ya.sync(function()
    return tostring(cx.active.current.cwd)
end)

local get_state = ya.sync(function(state)
    return state.bookmarks, state.path
end)

local set_bookmark = ya.sync(function(state, key, path)
    state.bookmarks[key] = path
end)

local function write(path, bookmarks)
    local file = io.open(path, 'w')
    if not file then
        return
    end
    local keys = {}
    for key in pairs(bookmarks) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        file:write(string.format('%s\t%s\n', key, bookmarks[key]))
    end
    file:close()
end

local function jump(bookmarks)
    local candidates = {}
    for key, path in pairs(bookmarks) do
        candidates[#candidates + 1] = { on = key, desc = path, path = path }
    end
    table.sort(candidates, function(a, b)
        return a.on < b.on
    end)
    local choice = ya.which({ cands = candidates })
    if choice then
        ya.emit('cd', { candidates[choice].path })
    end
end

local function save(path)
    local candidates = {}
    local keys = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for i = 1, #keys do
        local key = keys:sub(i, i)
        candidates[#candidates + 1] = { on = key, desc = 'Set bookmark ' .. key }
    end
    local choice = ya.which({ cands = candidates })
    if not choice then
        return
    end
    local key = candidates[choice].on
    local cwd = get_cwd()
    set_bookmark(key, cwd)
    local updated = get_state()
    write(path, updated)
end

return {
    setup = function(state, options)
        state.path = options.path
        state.bookmarks = options.bookmarks or {}
        local file = io.open(state.path, 'r')
        if file then
            for line in file:lines() do
                local key, path = line:match('^(.)\t(.+)$')
                if key and path then
                    state.bookmarks[key] = path
                end
            end
            file:close()
        end
        write(state.path, state.bookmarks)
    end,
    entry = function(_, job)
        local bookmarks, path = get_state()
        if job.args[1] == 'save' then
            save(path)
        elseif job.args[1] == 'jump' then
            jump(bookmarks)
        end
    end,
}
