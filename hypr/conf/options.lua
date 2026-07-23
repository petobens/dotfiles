hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = '#61afef',
            inactive_border = '#282c34',
        },
        layout = 'dwindle',
        resize_on_border = true,
    },
    decoration = {
        rounding = 4,
        active_opacity = 1,
        inactive_opacity = 1,
        shadow = { enabled = true, color = '#00000055', range = 12 },
        blur = { enabled = true, size = 6, passes = 2 },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    input = {
        kb_layout = 'us',
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        force_default_wallpaper = 0,
    },
})

hl.curve('easeOut', { type = 'bezier', points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = 'windows', enabled = true, speed = 4, bezier = 'easeOut' })
hl.animation({
    leaf = 'workspaces',
    enabled = true,
    speed = 4,
    bezier = 'easeOut',
    style = 'slide',
})
hl.animation({ leaf = 'fade', enabled = true, speed = 3, bezier = 'easeOut' })
hl.gesture({ fingers = 3, direction = 'horizontal', action = 'workspace' })
