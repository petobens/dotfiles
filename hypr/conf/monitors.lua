-- luacheck: globals hl

local external_left = 'DP-1'
local external_right = 'DP-3'
local laptop = 'eDP-1'
local full_hd = '1920x1080@60'

-- Two 1080p displays above the centered X1 Carbon screen
hl.monitor({ output = external_left, mode = full_hd, position = '0x0', scale = 1 })
hl.monitor({ output = external_right, mode = full_hd, position = '1920x0', scale = 1 })
hl.monitor({ output = laptop, mode = 'preferred', position = '960x1080', scale = 1.5 })

-- Other displays
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })

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
