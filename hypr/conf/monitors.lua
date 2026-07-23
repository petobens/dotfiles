-- Safe fallback for unknown displays
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })

-- LG UltraGear 39GX950B. Enable after checking the connector with
-- `hyprctl monitors all`; available refresh modes depend on the GPU and cable.
-- hl.monitor({
--     output = 'DP-1', mode = '3840x2400@165', position = '0x0',
--     scale = 1.25, vrr = 2,
-- })
-- hl.monitor({
--     output = 'eDP-1', mode = 'preferred', position = 'auto-left', scale = 1.5,
-- })

hl.workspace_rule({ workspace = '1', default = true })
hl.workspace_rule({ workspace = '5', default_name = 'terminal' })
