-- luacheck: globals hl

-- Outputs
local physical_outputs = {
    -- Add other familiar monitors to these lists, in preference order
    left = {
        'desc:Samsung Electric Company LF24T35 H9VT203938',
        'desc:Lenovo Group Limited LEN S24e-10 0x37353833',
    },
    right = {
        'desc:Samsung Electric Company LF24T35 H9VT203922',
        'desc:Lenovo Group Limited LEN S24e-10 0x37353832',
    },
    laptop = 'eDP-1',
}
local virtual_outputs = {
    left = 'Virtual-2',
    right = 'Virtual-3',
    laptop = 'Virtual-1',
}
local scale_by_resolution = {
    ['1920x1080'] = 1,
    ['2560x2160'] = 1.55,
    ['2880x1800'] = 1.5,
    ['3000x2000'] = 2,
    ['3840x2160'] = 2,
}
local active_mode
local lid_closed = false
local known_monitors = {}
local physical_workspace_outputs = { laptop = physical_outputs.laptop }
local workspace_outputs = physical_outputs
local workspace_to_restore

-- Helpers
local function connected_monitors()
    local monitors = hl.get_monitors({ all = true })
    -- Retain unplugged outputs so layout changes also update their rules
    for _, monitor in ipairs(monitors) do
        known_monitors[monitor.name] = monitor
    end
    return monitors
end

local function is_virtual_monitor(name)
    return name:match('^Virtual%-%d+$')
end

local function resolve_physical_outputs(monitors)
    local external = {}
    for _, monitor in ipairs(monitors) do
        if
            monitor.name ~= physical_outputs.laptop
            and not is_virtual_monitor(monitor.name)
        then
            external[#external + 1] = monitor
        end
    end
    -- Distinct descriptions keep unfamiliar pairs ordered when DP names change
    table.sort(external, function(a, b)
        if a.description == b.description then
            return a.name < b.name
        end
        return a.description < b.description
    end)

    local outputs = { laptop = physical_outputs.laptop }
    local fallback = external[1] and external[1].name
    for index, monitor in ipairs(external) do
        -- Both PBP halves have the same description; the laptop HDMI feeds the left
        if
            monitor.name == 'HDMI-A-1'
            and monitor.description:match('^Samsung Electric Company Odyssey G75F ')
        then
            outputs.left = monitor.name
            table.remove(external, index)
            break
        end
    end
    for _, role in ipairs({ 'left', 'right' }) do
        for _, selector in ipairs(physical_outputs[role]) do
            if outputs[role] then
                break
            end
            for index, monitor in ipairs(external) do
                if
                    monitor.name == selector
                    or 'desc:' .. monitor.description == selector
                then
                    outputs[role] = monitor.name
                    table.remove(external, index)
                    break
                end
            end
            if outputs[role] then
                break
            end
        end
    end
    for _, role in ipairs({ 'left', 'right' }) do
        if not outputs[role] then
            local monitor = table.remove(external, 1)
            -- A single external display takes both workspace groups
            outputs[role] = (monitor and monitor.name)
                or fallback
                or physical_outputs[role][1]
        end
    end
    return outputs
end

local function monitor_scale(monitor)
    if is_virtual_monitor(monitor.name) then
        -- Keep resizable QEMU displays near 1920 logical pixels
        local scale = math.floor(monitor.width / 1920 * 4 + 0.5) / 4
        return math.max(scale, 1)
    end

    local resolution = string.format('%dx%d', monitor.width, monitor.height)
    return scale_by_resolution[resolution] or 'auto'
end

-- Monitor configuration
local function configure_monitor(name, position, mirror)
    local monitor = known_monitors[name]
    if is_virtual_monitor(name) then
        hl.env('ROFI_DPI', '96')
    end

    hl.monitor({
        output = name,
        mode = 'preferred',
        position = position,
        scale = monitor.name and monitor_scale(monitor) or 'auto',
        mirror = mirror or '',
        disabled = false,
    })
end

local function configure_laptop()
    for _, monitor in ipairs(connected_monitors()) do
        if monitor.name == physical_outputs.laptop then
            configure_monitor(monitor.name, '0x0')
            return true
        end
    end
    return false
end

local function configure_all_monitors()
    hl.config({ debug = { damage_tracking = 2 } })
    local monitors = connected_monitors()
    physical_workspace_outputs = resolve_physical_outputs(monitors)
    local laptop = known_monitors[physical_outputs.laptop]
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = '',
        disabled = false,
    })
    for name, monitor in pairs(known_monitors) do
        local position = name == physical_outputs.laptop and '0x0' or 'auto'
        if
            (
                name == physical_workspace_outputs.left
                or name == physical_workspace_outputs.right
            )
            and monitor.name
            and laptop
            and laptop.name
        then
            -- Place the external pair's seam above the laptop's center
            local scale = tonumber(monitor_scale(monitor)) or monitor.scale
            local laptop_scale = tonumber(monitor_scale(laptop)) or laptop.scale
            -- Match Hyprland's rounded logical dimensions to avoid gaps or overlaps
            local width = math.floor(monitor.width / scale + 0.5)
            local height = math.floor(monitor.height / scale + 0.5)
            local x = math.floor(laptop.width / laptop_scale + 0.5) / 2
            if physical_workspace_outputs.left == physical_workspace_outputs.right then
                x = x - width / 2
            elseif name == physical_workspace_outputs.left then
                x = x - width
            end
            position = string.format('%dx%d', math.floor(x), -height)
        end
        configure_monitor(name, position)
    end
end

-- Workspace rules
local function configure_workspace_rules(outputs)
    if outputs == physical_outputs then
        outputs = resolve_physical_outputs(connected_monitors())
        physical_workspace_outputs = outputs
    end
    -- When both external groups share a display, only workspace 5 is the default
    for _, workspace in ipairs({
        { '1', outputs.right, outputs.right ~= outputs.left },
        { '2', outputs.laptop, true },
        { '3', outputs.laptop },
        { '4', outputs.right },
        { '5', outputs.left, true },
        { '6', outputs.left },
        { '7', outputs.left },
        { '8', outputs.laptop },
        { '9', outputs.right },
    }) do
        hl.workspace_rule({
            workspace = workspace[1],
            monitor = workspace[2],
            default = workspace[3] or false,
        })
        local current = hl.get_workspace(workspace[1])
        local monitor = hl.get_monitor(workspace[2])
        if
            active_mode == 'multi'
            and not lid_closed
            and current
            and monitor
            and current.monitor.name ~= monitor.name
        then
            hl.dispatch(hl.dsp.workspace.move({ workspace = current, monitor = monitor }))
        end
    end
end

-- Workspace focus
local function cycle_focus()
    local monitors = hl.get_monitors()
    -- Cycle across the top row before the laptop below it
    table.sort(monitors, function(a, b)
        if a.y == b.y then
            return a.x < b.x
        end
        return a.y < b.y
    end)
    for index, monitor in ipairs(monitors) do
        if monitor.focused then
            hl.dispatch(hl.dsp.focus({ monitor = monitors[index % #monitors + 1].name }))
            return
        end
    end
end

local function focus_development_workspace(monitor)
    -- A lone external output uses the development workspace
    if
        monitor
        and #hl.get_monitors() == 1
        and monitor.name ~= physical_outputs.laptop
    then
        hl.dispatch(hl.dsp.focus({ workspace = '5' }))
    end
end

local function activate_default_workspace(monitor)
    if active_mode ~= 'multi' or lid_closed then
        return
    end

    local outputs = physical_workspace_outputs
    local workspace
    if monitor.name == outputs.left then
        workspace = '5'
    elseif monitor.name == outputs.right then
        workspace = '1'
    elseif monitor.name == outputs.laptop then
        workspace = '2'
    end
    if not workspace then
        return
    end

    -- Added monitors already have a workspace before these rules are applied
    local focused = hl.get_active_monitor()
    hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    if focused and focused.name ~= monitor.name then
        hl.dispatch(hl.dsp.focus({ monitor = focused.name }))
    end
end

local function virtual_outputs_connected()
    return hl.get_monitor(virtual_outputs.laptop)
        and hl.get_monitor(virtual_outputs.left)
        and hl.get_monitor(virtual_outputs.right)
end

local function configure_virtual_workspaces()
    if workspace_outputs == virtual_outputs or not virtual_outputs_connected() then
        return
    end

    -- QEMU outputs arrive after startup, so replace the physical rules once
    workspace_outputs = virtual_outputs
    configure_workspace_rules(workspace_outputs)
    for _, workspace in ipairs({ '2', '5', '1' }) do
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    end
end

-- Monitor layouts
local function primary()
    if not configure_laptop() then
        return
    end

    active_mode = 'primary'
    hl.config({ debug = { damage_tracking = 2 } })
    for name in pairs(known_monitors) do
        if name ~= physical_outputs.laptop then
            hl.monitor({ output = name, disabled = true })
        end
    end
    hl.monitor({ output = '', disabled = true })
end

local function mirror()
    -- Duplicate the laptop screen on every other display (projectors, TVs)
    if not configure_laptop() then
        return
    end

    active_mode = 'mirror'
    -- Redraw whole frames so mirror side bars do not retain old screen content
    hl.config({ debug = { damage_tracking = 1 } })
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = physical_outputs.laptop,
        disabled = false,
    })
    for name in pairs(known_monitors) do
        if name ~= physical_outputs.laptop then
            configure_monitor(name, 'auto', physical_outputs.laptop)
        end
    end
end

local function multi()
    active_mode = 'multi'
    configure_all_monitors()
    -- Restore workspace placement after the monitor rules have been applied
    hl.timer(function()
        if active_mode == 'multi' and not lid_closed then
            configure_workspace_rules(workspace_outputs)
            for _, monitor in ipairs(hl.get_monitors()) do
                activate_default_workspace(monitor)
            end
        end
    end, { timeout = 1, type = 'oneshot' })
end

-- Preserve and restore the selected layout across lid and monitor events
local function external_only()
    configure_all_monitors()
    for _, monitor in ipairs(connected_monitors()) do
        if monitor.name ~= physical_outputs.laptop then
            hl.monitor({ output = physical_outputs.laptop, disabled = true })
            break
        end
    end
end

local function restore_active_mode()
    if lid_closed then
        external_only()
    elseif active_mode == 'primary' then
        primary()
    elseif active_mode == 'mirror' then
        mirror()
    else
        multi()
    end
end

-- Keep the selected workspace when a layout shortcut is used
local function restore_workspace()
    -- Use a second timer turn so every monitor's default-workspace timer runs first
    hl.timer(function()
        hl.timer(function()
            if workspace_to_restore then
                hl.dispatch(hl.dsp.focus({ workspace = workspace_to_restore }))
                workspace_to_restore = nil
            end
        end, { timeout = 1, type = 'oneshot' })
    end, { timeout = 1, type = 'oneshot' })
end

local function keep_workspace(apply_layout)
    return function()
        local workspace = hl.get_active_workspace()
        workspace_to_restore = workspace and workspace.name
        local previous_mode = active_mode
        apply_layout()
        -- An unchanged layout or a lone output may not emit a layout-change event
        if active_mode == previous_mode or #connected_monitors() == 1 then
            restore_workspace()
        end
    end
end

-- Monitor events
hl.on('monitor.layout_changed', restore_workspace)
hl.on('monitor.added', function(monitor)
    restore_active_mode()
    configure_virtual_workspaces()
    if workspace_outputs ~= virtual_outputs then
        configure_workspace_rules(physical_outputs)
        activate_default_workspace(monitor)
    end
    focus_development_workspace(monitor)
end)
hl.on('hyprland.start', function()
    for _, monitor in ipairs(hl.get_monitors()) do
        activate_default_workspace(monitor)
    end
    focus_development_workspace(hl.get_monitors()[1])
end)
hl.on('monitor.removed', function()
    -- Wait for unplug cleanup before checking which cached monitors still exist
    hl.timer(function()
        restore_active_mode()
        configure_workspace_rules(workspace_outputs)
    end, { timeout = 1, type = 'oneshot' })
end)

-- Lid switch events
hl.bind('switch:on:Lid Switch', function()
    lid_closed = true
    restore_active_mode()
end, { description = 'Disable laptop display on lid close', locked = true })

hl.bind('switch:off:Lid Switch', function()
    lid_closed = false
    restore_active_mode()
end, { description = 'Restore laptop display on lid open', locked = true })

-- Initial state
active_mode = 'multi'
configure_all_monitors()
workspace_outputs = virtual_outputs_connected() and virtual_outputs or physical_outputs
configure_workspace_rules(workspace_outputs)

return {
    primary = keep_workspace(primary),
    multi = keep_workspace(multi),
    mirror = keep_workspace(mirror),
    cycle_focus = cycle_focus,
}
