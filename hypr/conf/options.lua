-- luacheck: globals hl

-- General
hl.config({
    general = {
        layout = 'dwindle',
        gaps_in = 4,
        gaps_out = 4,
        border_size = 2,
        col = {
            active_border = '#3e4451',
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
            enabled = false,
        },
    },
    animations = { enabled = true },
    -- Hide the pointer while it sits still, as unclutter did under X
    cursor = { inactive_timeout = 1 },
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

-- Animation curves
-- Control points of a cubic bezier, as in CSS cubic-bezier(x1, y1, x2, y2)
-- easeOutQuint starts at full speed, so the workspace slide jolts on its first
-- frame. Ease into the same peak speed instead, over a shorter duration
local animation_curve = 'easeOutQuint'
hl.curve(animation_curve, {
    type = 'bezier',
    points = { { 0.23, 1 }, { 0.32, 1 } },
})

local workspace_curve = 'easeInOutStandard'
hl.curve(workspace_curve, {
    type = 'bezier',
    points = { { 0.4, 0 }, { 0.2, 1 } },
})

-- Animations
-- A leaf names a node of Hyprland's animation tree, and its settings apply to
-- every child node. Speed is the duration in tenths of a second, so 5 is half a
-- second. See the full tree with `hyprctl animations`.
hl.animation({ leaf = 'windows', enabled = true, speed = 5, bezier = animation_curve })
hl.animation({
    leaf = 'workspaces',
    enabled = true,
    speed = 3,
    bezier = workspace_curve,
    style = 'slide',
})
hl.animation({ leaf = 'fade', enabled = true, speed = 3, bezier = animation_curve })

-- Gestures
hl.gesture({ fingers = 3, direction = 'horizontal', action = 'workspace' })
