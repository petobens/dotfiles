--- @since 26.5.6
-- luacheck: globals ya cx Command Url

local context = ya.sync(function()
    local current = cx.active.current
    local hovered = current.hovered
    return tostring(current.cwd),
        hovered and tostring(hovered.url.parent) or tostring(current.cwd)
end)

local function choose(command, cwd)
    local permit = ya.hide()
    local output, err = Command('sh')
        :arg({ '-c', command })
        :cwd(cwd)
        :stdin(Command.INHERIT)
        :stdout(Command.PIPED)
        :stderr(Command.INHERIT)
        :output()
    permit:drop()

    if not output then
        ya.notify({
            title = 'FZF',
            content = tostring(err),
            level = 'error',
            timeout = 5,
        })
        return nil
    end
    if not output.status.success then
        return nil
    end
    return output.stdout:gsub('[%z\r\n]+$', '')
end

local function parent_command(start)
    local paths = {}
    local current = Url(start)
    while current do
        paths[#paths + 1] = ya.quote(tostring(current))
        if tostring(current) == '/' then
            break
        end
        current = current.parent
    end
    return "printf '%s\\n' "
        .. table.concat(paths, ' ')
        .. " | fzf --no-multi --scheme=path --border-label='Parent Dirs' "
        .. "--preview='eza -F --tree --level=2 --color=always "
        .. "--icons=always {} | head -200'"
end

local function entry(_, job)
    local mode = job.args[1]
    local cwd, hovered_parent = context()
    local command

    if mode == 'parents' then
        command = parent_command(hovered_parent)
    else
        local kind = mode == 'dirs' and 'd' or 'f'
        local ignore = job.args.no_ignore and ' --no-ignore-vcs' or ''
        local label = mode == 'dirs' and 'Find Dirs' or 'Find Files'
        local preview = mode == 'dirs'
                and 'eza -F --tree --level=2 --color=always --icons=always {} | head -200'
            or 'bat --line-range :200 {}'
        command = 'fd --type '
            .. kind
            .. ' --hidden --follow --exclude .git --color never --print0'
            .. ignore
            .. " | fzf --read0 --print0 --no-multi --scheme=path --border-label='"
            .. label
            .. "' --preview="
            .. ya.quote(preview)
    end

    local selected = choose(command, cwd)
    if not selected or selected == '' then
        return
    end
    if mode == 'files' then
        ya.emit('reveal', { Url(cwd):join(selected) })
    else
        ya.emit('cd', { selected })
    end
end

return { entry = entry }
