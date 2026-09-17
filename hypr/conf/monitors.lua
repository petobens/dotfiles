-- luacheck: globals hl

-- Outputs
local physical_outputs = {
    left = 'DP-1',
    right = 'DP-3',
    laptop = 'eDP-1',
}
-- Alternate port names for the left and right monitors
local output_aliases = {
    ['DP-5'] = physical_outputs.left,
    ['DP-6'] = physical_outputs.right,
}
local virtual_outputs = {
    left = 'Virtual-2',
    right = 'Virtual-3',
    laptop = 'Virtual-1',
}
local scale_by_resolution = {
    ['1920x1080'] = 1,
    ['2880x1800'] = 1.5,
    ['3000x2000'] = 2,
    ['3840x2160'] = 2,
}
local positions = {
    [physical_outputs.left] = '-960x-1080',
    [physical_outputs.right] = '960x-1080',
    [physical_outputs.laptop] = '0x0',
}
local active_mode
local lid_closed = false
local known_monitors = {}

-- Helpers
local function connected_monitors()
    -- Queries omit disabled and mirrored outputs, so retain their weak references
    for _, monitor in ipairs(hl.get_monitors()) do
        known_monitors[monitor.name] = monitor
        for _, mirrored in ipairs(monitor.mirrors) do
            known_monitors[mirrored.name] = mirrored
        end
    end
    local monitors = {}
    -- Keep expired entries so layout changes also update unplugged output rules
    for _, monitor in pairs(known_monitors) do
        if monitor.name then
            monitors[#monitors + 1] = monitor
        end
    end
    return monitors
end

local function is_virtual_monitor(name)
    return name:match('^Virtual%-%d+$')
end

local function monitor_position(name)
    return positions[output_aliases[name] or name]
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
            configure_monitor(monitor.name, positions[physical_outputs.laptop])
            return true
        end
    end
    return false
end

local function configure_all_monitors()
    hl.config({ debug = { damage_tracking = 2 } })
    local monitors = connected_monitors()
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
        local position = monitor_position(name) or 'auto'
        if
            #monitors == 2
            and name ~= physical_outputs.laptop
            and monitor.name
            and laptop
            and laptop.name
        then
            -- Center a single external display above the laptop in logical pixels
            local scale = tonumber(monitor_scale(monitor)) or monitor.scale
            local laptop_scale = tonumber(monitor_scale(laptop)) or laptop.scale
            local x = (laptop.width / laptop_scale - monitor.width / scale) / 2
            local y = -monitor.height / scale
            position = string.format('%dx%d', math.floor(x), math.ceil(y))
        end
        configure_monitor(name, position)
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

-- Workspace rules
local function focus_development_workspace(monitor)
    -- A lone output outside the physical layout uses the development workspace
    if monitor and #hl.get_monitors() == 1 and not monitor_position(monitor.name) then
        hl.dispatch(hl.dsp.focus({ workspace = '5' }))
    end
end

local physical_workspace_outputs = physical_outputs

local function configure_workspace_rules(outputs)
    if outputs == physical_outputs then
        local external = {}
        local hdmi
        for _, monitor in ipairs(connected_monitors()) do
            if monitor.name ~= physical_outputs.laptop then
                external[#external + 1] = monitor.name
            end
            if monitor.name:match('^HDMI%-') then
                hdmi = hdmi or monitor.name
            end
        end
        local fallback = #external == 1 and external[1] or hdmi
        outputs = {}
        for role, name in pairs(physical_outputs) do
            local monitor = known_monitors[name]
            local output = monitor and monitor.name
            for alias, canonical in pairs(output_aliases) do
                monitor = known_monitors[alias]
                if not output and canonical == name and monitor and monitor.name then
                    output = alias
                end
            end
            -- A lone external display takes both external workspace groups
            outputs[role] = output or (role ~= 'laptop' and fallback) or name
        end
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
    end
end

local workspace_outputs

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

    -- Added monitors already have a workspace before alias rules are applied
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

-- Monitor events
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
multi()
workspace_outputs = virtual_outputs_connected() and virtual_outputs or physical_outputs
configure_workspace_rules(workspace_outputs)
focus_development_workspace(hl.get_monitors()[1])
return { primary = primary, multi = multi, mirror = mirror, cycle_focus = cycle_focus }
