-- luacheck: globals hl

-- Outputs
local physical_outputs = {
    left = 'DP-1',
    right = 'DP-3',
    laptop = 'eDP-1',
}
local virtual_outputs = {
    left = 'Virtual-2',
    right = 'Virtual-3',
    laptop = 'Virtual-1',
}
local scale_by_resolution = {
    ['1920x1080'] = 1,
    ['2880x1800'] = 1.5,
    ['3840x2160'] = 2,
}
local positions = {
    [physical_outputs.left] = '-960x-1080',
    [physical_outputs.right] = '960x-1080',
    [physical_outputs.laptop] = '0x0',
}
local active_mode
local lid_closed = false

-- Monitor layouts
local function monitor_scale(monitor)
    if monitor.name:match('^Virtual%-%d+$') then
        -- Keep resizable QEMU displays near 1920 logical pixels
        local scale = math.floor(monitor.width / 1920 * 4 + 0.5) / 4
        return math.max(scale, 1)
    end

    local resolution = string.format('%dx%d', monitor.width, monitor.height)
    return scale_by_resolution[resolution] or 'auto'
end

local function configure_monitor(monitor, position, mirror)
    hl.monitor({
        output = monitor.name,
        mode = 'preferred',
        position = position,
        scale = monitor_scale(monitor),
        mirror = mirror or '',
        disabled = false,
    })
end

local function configure_laptop()
    local monitor = hl.get_monitor(physical_outputs.laptop)
    if not monitor then
        return false
    end

    configure_monitor(monitor, positions[physical_outputs.laptop])
    return true
end

local function configure_all_monitors()
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = '',
        disabled = false,
    })
    for _, monitor in ipairs(hl.get_monitors()) do
        configure_monitor(monitor, positions[monitor.name] or 'auto')
    end
end

local function primary()
    if not configure_laptop() then
        return
    end

    active_mode = 'primary'
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= physical_outputs.laptop then
            hl.monitor({ output = monitor.name, disabled = true })
        end
    end
    hl.monitor({ output = '', disabled = true })
end

-- Duplicate the laptop screen on every other display (projectors, TVs)
local function mirror()
    if not configure_laptop() then
        return
    end

    active_mode = 'mirror'
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = physical_outputs.laptop,
        disabled = false,
    })
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= physical_outputs.laptop then
            configure_monitor(monitor, 'auto', physical_outputs.laptop)
        end
    end
end

local function multi()
    active_mode = 'multi'
    configure_all_monitors()
end

-- Preserve and restore the selected layout across lid and monitor events
local function external_only()
    local previous_mode = active_mode
    multi()
    active_mode = previous_mode
    hl.monitor({ output = physical_outputs.laptop, disabled = true })
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
    if monitor and #hl.get_monitors() == 1 and not positions[monitor.name] then
        hl.dispatch(hl.dsp.focus({ workspace = '5' }))
    end
end

local function configure_workspace_rules(outputs)
    for _, workspace in ipairs({
        { '1', outputs.right, true },
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
            default = workspace[3],
        })
    end
end

local workspace_outputs

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
    focus_development_workspace(monitor)
end)
hl.on('monitor.removed', restore_active_mode)

-- Lid switch events
hl.bind('switch:on:Lid Switch', function()
    lid_closed = true
    restore_active_mode()
end, { description = 'Disable laptop display on lid close', locked = true })

hl.bind('switch:off:Lid Switch', function()
    lid_closed = false
    local previous_mode = active_mode
    multi()
    active_mode = previous_mode
end, { description = 'Restore laptop display on lid open', locked = true })

-- Initial state
multi()
workspace_outputs = virtual_outputs_connected() and virtual_outputs or physical_outputs
configure_workspace_rules(workspace_outputs)
focus_development_workspace(hl.get_monitors()[1])
return { primary = primary, multi = multi, mirror = mirror }
