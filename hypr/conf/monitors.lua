-- Two 1080p displays above the centered X1 Carbon screen
hl.monitor({ output = 'DP-1', mode = '1920x1080@60', position = '0x0', scale = 1 })
hl.monitor({ output = 'DP-3', mode = '1920x1080@60', position = '1920x0', scale = 1 })
hl.monitor({ output = 'eDP-1', mode = 'preferred', position = '960x1080', scale = 1.5 })

-- Safe fallback for other displays
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })

hl.workspace_rule({ workspace = '1', monitor = 'eDP-1', default = true })
hl.workspace_rule({ workspace = '5', default_name = 'terminal' })
