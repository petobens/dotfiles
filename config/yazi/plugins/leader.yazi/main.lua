--- @since 26.5.6
-- luacheck: globals ya

local function mapping(on, desc, action, args)
    return { on = on, desc = desc, action = action, args = args }
end

local function group(on, desc, choices)
    return { on = on, desc = desc, choices = choices }
end

local groups = {
    group('v', 'View or split', {
        mapping('m', 'Toggle pane layout', 'plugin', {
            'toggle-pane',
            'max-current',
        }),
        mapping('s', 'Create tab', 'tab_create', { current = true }),
    }),
    group('r', 'Remove permanently', {
        mapping('m', 'Permanently delete selected files', 'remove', {
            permanently = true,
        }),
    }),
    group('n', 'New tab', {
        mapping('t', 'Create tab', 'tab_create', { current = true }),
    }),
    group('w', 'Close tab', {
        mapping('d', 'Close tab', 'close'),
    }),
    group('s', 'Sort', {
        mapping('t', 'Sort by extension', 'sort', {
            'extension',
            reverse = 'no',
        }),
        mapping('T', 'Sort by extension in reverse', 'sort', {
            'extension',
            reverse = 'yes',
        }),
        mapping('m', 'Sort by modification time, newest first', 'sort', {
            'mtime',
            reverse = 'yes',
        }),
        mapping('M', 'Sort by modification time, oldest first', 'sort', {
            'mtime',
            reverse = 'no',
        }),
        mapping('s', 'Sort by size, largest first', 'sort', {
            'size',
            reverse = 'yes',
        }),
        mapping('S', 'Sort by size, smallest first', 'sort', {
            'size',
            reverse = 'no',
        }),
        mapping('a', 'Sort alphabetically', 'sort', {
            'alphabetical',
            reverse = 'no',
        }),
        mapping('A', 'Sort alphabetically in reverse', 'sort', {
            'alphabetical',
            reverse = 'yes',
        }),
    }),
    group('l', 'Line mode', {
        mapping('m', 'Show size and modification time', 'linemode', {
            'size_and_mtime',
        }),
    }),
    group('t', 'Toggle', {
        mapping('h', 'Toggle hidden files', 'hidden', { 'toggle' }),
    }),
    group('b', 'Bookmarks', {
        mapping('m', 'Show bookmarks', 'plugin', {
            'bookmarks',
            'jump',
        }),
    }),
    group('a', 'Add bookmark', {
        mapping('b', 'Add bookmark', 'plugin', {
            'bookmarks',
            'save',
        }),
    }),
    group('u', 'Unpack', {
        mapping('p', 'Extract archive', 'open', { hovered = true }),
    }),
    group('o', 'Open externally', {
        mapping('d', 'Drag and drop selected files', 'shell', {
            'dragon-drop -a -x %s',
            orphan = true,
        }),
    }),
}

for tab = 1, 9 do
    groups[#groups + 1] = mapping(tostring(tab), 'Tab ' .. tab, 'tab_switch', { tab - 1 })
end

local function choose(candidates)
    local choice = ya.which({ cands = candidates })
    return choice and candidates[choice] or nil
end

local function emit(item)
    ya.emit(item.action, item.args or {})
end

return {
    entry = function()
        local item = choose(groups)
        if not item then
            return
        end
        if item.choices then
            item = choose(item.choices)
        end
        if item then
            emit(item)
        end
    end,
}
