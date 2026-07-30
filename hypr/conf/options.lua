-- luacheck: globals hl

local animation_curve = 'easeOut'

-- General
hl.config({
    general = {
        layout = 'dwindle',
        gaps_in = 4,
        gaps_out = 4,
        border_size = 2,
        col = {
            active_border = '#4b5263',
            inactive_border = '#282c34',
        },
        resize_on_border = true,
    },
    decoration = {
        active_opacity = 1,
        inactive_opacity = 1,
        rounding = 4,
        blur = {
            enabled = true,
            passes = 2,
            size = 6,
        },
        shadow = {
            enabled = true,
            color = '#00000055',
            range = 12,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    ecosystem = { no_update_news = true },
    input = {
        follow_mouse = 1,
        kb_layout = 'personal,personal',
        kb_options = 'grp:win_space_toggle,ctrl:nocaps',
        kb_variant = 'us,es',
        sensitivity = 0,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            tap_to_click = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        force_default_wallpaper = 0,
    },
})

-- Animations and gestures
hl.curve(animation_curve, {
    type = 'bezier',
    points = { { 0.16, 1 }, { 0.3, 1 } },
})
hl.animation({ leaf = 'windows', enabled = true, speed = 4, bezier = animation_curve })
hl.animation({
    leaf = 'workspaces',
    enabled = true,
    speed = 4,
    bezier = animation_curve,
    style = 'slide',
})
hl.animation({ leaf = 'fade', enabled = true, speed = 3, bezier = animation_curve })
hl.gesture({ fingers = 3, direction = 'horizontal', action = 'workspace' })
