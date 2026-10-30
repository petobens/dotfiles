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
    portable = 'GWD ARZOPA 0x0965020C',
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
local monitor_audio_active = false
local known_monitors = {}
local physical_workspace_outputs = { laptop = physical_outputs.laptop }
local workspace_outputs = physical_outputs
local workspace_to_restore

-- Helpers
local function read_lid_state()
    local state = io.open('/proc/acpi/button/lid/LID/state')
    if not state then
        return lid_closed
    end
    local closed = state:read('*a'):match('closed') ~= nil
    state:close()
    return closed
end

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
    local outputs = { laptop = physical_outputs.laptop }
    for _, monitor in ipairs(monitors) do
        if monitor.description == physical_outputs.portable then
            outputs.portable = monitor.name
            if lid_closed then
                outputs.laptop = monitor.name
            end
        elseif
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

    local fallback = (external[1] and external[1].name) or outputs.portable
    for index, monitor in ipairs(external) do
        -- PBP inputs share a description but report different physical widths
        -- The current left input reports 930 mm, independent of dock port numbering
        if
            monitor.physical_width == 930
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

    local mode = 'preferred'
    -- The G7 DP input often stays black at 120 Hz through the dock
    if
        monitor.name
        and monitor.description:match('^Samsung Electric Company Odyssey G75F ')
    then
        mode = string.format('%dx%d@60', monitor.width, monitor.height)
    end
    hl.monitor({
        output = name,
        mode = mode,
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
    local laptop = known_monitors[physical_workspace_outputs.laptop]
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = '',
        disabled = false,
    })
    for name, monitor in pairs(known_monitors) do
        local position = name == physical_workspace_outputs.laptop and '0x0' or 'auto'
        if
            (
                name == physical_workspace_outputs.left
                or name == physical_workspace_outputs.right
            )
            and name ~= physical_workspace_outputs.laptop
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
        if lid_closed and name == physical_outputs.laptop and #monitors > 1 then
            hl.monitor({ output = name, disabled = true })
        else
            configure_monitor(name, position)
        end
    end
end

-- Workspace rules
local function configure_workspace_rules(outputs)
    if outputs == physical_outputs then
        outputs = resolve_physical_outputs(connected_monitors())
        physical_workspace_outputs = outputs
    end
    -- Shared outputs get one default workspace, with the laptop role taking priority
    local workspaces = {
        {
            '1',
            outputs.right,
            outputs.right ~= outputs.left
                and outputs.right ~= outputs.laptop
                and outputs.right ~= outputs.portable,
        },
        { '2', outputs.laptop, true },
        { '3', outputs.laptop },
        { '4', outputs.right },
        {
            '5',
            outputs.left,
            outputs.left ~= outputs.laptop and outputs.left ~= outputs.portable,
        },
        { '6', outputs.left },
        { '7', outputs.left },
        { '8', outputs.laptop },
        { '9', outputs.right },
    }
    if outputs.portable then
        workspaces[#workspaces + 1] = { '10', outputs.portable, not lid_closed }
    end
    for _, workspace in ipairs(workspaces) do
        hl.workspace_rule({
            workspace = workspace[1],
            monitor = workspace[2],
            default = workspace[3] or false,
        })
        local current = hl.get_workspace(workspace[1])
        local monitor = hl.get_monitor(workspace[2])
        if
            (active_mode == 'multi' or lid_closed)
            and current
            and monitor
            and monitor.enabled
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
        and monitor.name ~= physical_workspace_outputs.laptop
    then
        hl.dispatch(hl.dsp.focus({ workspace = '5' }))
    end
end

local function activate_default_workspace(monitor)
    if active_mode ~= 'multi' and not lid_closed then
        return
    end

    local outputs = physical_workspace_outputs
    local workspace
    if monitor.name == outputs.laptop then
        workspace = '2'
    elseif monitor.name == outputs.portable and not lid_closed then
        workspace = '10'
    elseif monitor.name == outputs.left then
        workspace = '5'
    elseif monitor.name == outputs.right then
        workspace = '1'
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

local function schedule_workspace_layout()
    -- Restore workspace placement after the monitor rules have been applied
    hl.timer(function()
        if active_mode == 'multi' or lid_closed then
            configure_workspace_rules(workspace_outputs)
            for _, monitor in ipairs(hl.get_monitors()) do
                activate_default_workspace(monitor)
            end
        end
    end, { timeout = 1, type = 'oneshot' })
end

local function multi()
    active_mode = 'multi'
    configure_all_monitors()
    schedule_workspace_layout()
end

-- Preserve and restore the selected layout across lid and monitor events
local function restore_active_mode()
    if lid_closed then
        configure_all_monitors()
        schedule_workspace_layout()
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

local function keep_workspace(mode, apply_layout)
    return function()
        local workspace = hl.get_active_workspace()
        workspace_to_restore = workspace and workspace.name
        local previous_mode = active_mode
        if lid_closed then
            -- Remember the layout for when the lid opens; keep the laptop off until then
            active_mode = mode
            restore_active_mode()
        else
            apply_layout()
        end
        -- An unchanged layout or a lone output may not emit a layout-change event
        if lid_closed or active_mode == previous_mode or #connected_monitors() == 1 then
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
    monitor_audio_active = false
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
local function update_lid_state()
    local closed = read_lid_state()
    if closed == lid_closed then
        return
    end
    lid_closed = closed
    restore_active_mode()
    configure_workspace_rules(workspace_outputs)
end

hl.bind('switch:on:Lid Switch', update_lid_state, {
    description = 'Disable laptop display on lid close',
    locked = true,
})
hl.bind('switch:off:Lid Switch', update_lid_state, {
    description = 'Restore laptop display on lid open',
    locked = true,
})

-- Make the ARZOPA speakers the default when the lid is closed next to the G7
local function monitor_audio_setup()
    local portable, samsung = false, false
    for _, monitor in ipairs(hl.get_monitors()) do
        portable = portable or monitor.description == physical_outputs.portable
        samsung = samsung
            or monitor.description:match('^Samsung Electric Company Odyssey G75F ')
                ~= nil
    end
    return lid_closed and portable and samsung
end

local function update_monitor_audio()
    local active = monitor_audio_setup()
    if active and not monitor_audio_active then
        hl.exec_cmd(os.getenv('HOME') .. '/.config/hypr/scripts/monitor_audio')
    end
    -- Apply once per setup change so manual audio selections remain possible
    monitor_audio_active = active
end

-- Recover missed switch events without reapplying the layout on every check
hl.timer(function()
    update_lid_state()
    update_monitor_audio()
end, { timeout = 1000, type = 'repeat' })

-- Initial state
lid_closed = read_lid_state()
-- Config reloads keep the current audio output; Hyprland start clears this flag
monitor_audio_active = monitor_audio_setup()
active_mode = 'multi'
workspace_outputs = virtual_outputs_connected() and virtual_outputs or physical_outputs
restore_active_mode()
configure_workspace_rules(workspace_outputs)

return {
    primary = keep_workspace('primary', primary),
    multi = keep_workspace('multi', multi),
    mirror = keep_workspace('mirror', mirror),
    cycle_focus = cycle_focus,
}
