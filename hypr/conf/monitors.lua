-- luacheck: globals hl

local external_left = 'DP-1'
local external_right = 'DP-3'
local laptop = 'eDP-1'
local scale_by_resolution = {
    ['1920x1080'] = 1,
    ['2880x1800'] = 1.5,
    ['3840x2160'] = 2,
}
local positions = {
    [external_left] = '0x0',
    [external_right] = '1920x0',
    [laptop] = '960x1080',
}
local active_mode

local function monitor_scale(monitor)
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

local function laptop_monitor(position)
    local monitor = hl.get_monitor(laptop)
    if monitor then
        configure_monitor(monitor, position)
    end
end

local function multi()
    active_mode = 'multi'
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
    -- Keep connected outputs enabled when no laptop panel is present
    local connected = false
    for _, monitor in ipairs(hl.get_monitors()) do
        connected = connected or monitor.name == laptop
    end
    if not connected then
        return multi()
    end

    active_mode = 'primary'
    laptop_monitor('0x0')
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= laptop then
            hl.monitor({ output = monitor.name, disabled = true })
        end
    end
    hl.monitor({ output = '', disabled = true })
end

-- Duplicate the laptop screen on every other display (projectors, TVs)
local function mirror()
    active_mode = 'mirror'
    laptop_monitor('0x0')
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 'auto',
        mirror = laptop,
        disabled = false,
    })
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= laptop then
            configure_monitor(monitor, 'auto', laptop)
        end
    end
end

hl.on('monitor.added', function()
    if active_mode == 'primary' then
        primary()
    elseif active_mode == 'mirror' then
        mirror()
    else
        multi()
    end
end)

-- Two external displays above the centered X1 Carbon screen
multi()

-- Workspaces
local workspaces = {
    { '1', external_right, true },
    { '2', laptop, true },
    { '3', laptop },
    { '4', external_right },
    { '5', external_left, true },
    { '6', external_left },
    { '7', external_left },
    { '8', laptop },
    { '9', external_right },
}
for _, workspace in ipairs(workspaces) do
    hl.workspace_rule({
        workspace = workspace[1],
        monitor = workspace[2],
        default = workspace[3],
    })
end

return { primary = primary, multi = multi, mirror = mirror }
