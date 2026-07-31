-- luacheck: globals hl

local external_left = 'DP-1'
local external_right = 'DP-3'
local laptop = 'eDP-1'
local full_hd = '1920x1080@60'
-- An empty output name matches every display without a rule of its own
local others = { external_left, external_right, '' }

local function laptop_monitor(position)
    hl.monitor({
        output = laptop,
        mode = 'preferred',
        position = position,
        scale = 1.5,
        disabled = false,
    })
end

local function multi()
    hl.monitor({
        output = external_left,
        mode = full_hd,
        position = '0x0',
        scale = 1,
        mirror = '',
        disabled = false,
    })
    hl.monitor({
        output = external_right,
        mode = full_hd,
        position = '1920x0',
        scale = 1,
        mirror = '',
        disabled = false,
    })
    laptop_monitor('960x1080')
    hl.monitor({
        output = '',
        mode = 'preferred',
        position = 'auto',
        scale = 1,
        mirror = '',
        disabled = false,
    })
end

local function primary()
    -- Disabling every other output without the laptop panel connected, as in
    -- the VM, would leave no display enabled at all
    local connected = false
    for _, monitor in ipairs(hl.get_monitors()) do
        connected = connected or monitor.name == laptop
    end
    if not connected then
        return multi()
    end

    laptop_monitor('0x0')
    for _, output in ipairs(others) do
        hl.monitor({ output = output, disabled = true })
    end
end

-- Duplicate the laptop screen on every other display (projectors, TVs)
local function mirror()
    laptop_monitor('0x0')
    for _, output in ipairs(others) do
        hl.monitor({
            output = output,
            mode = 'preferred',
            position = 'auto',
            scale = 1,
            mirror = laptop,
            disabled = false,
        })
    end
end

-- Two 1080p displays above the centered X1 Carbon screen
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
