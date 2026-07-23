-- Open applications floating by default
hl.window_rule({ match = { class = '.*' }, float = true, suppress_event = 'maximize' })

hl.window_rule({
    match = { class = '^(Slack|brave-teams|brave-meet|brave-gmail|zoom|Mailspring)$' },
    workspace = '2 silent',
})
hl.window_rule({ match = { class = '^(Spotify|mpv)$' }, workspace = '3 silent' })
hl.window_rule({ match = { class = '^(transmission-gtk|obs)$' }, workspace = '4 silent' })
hl.window_rule({ match = { class = '^com.mitchellh.ghostty$' }, maximize = true })

hl.window_rule({
    match = { class = '^(Spotify|Slack|brave-teams|zoom|Mailspring|mpv|obs)$' },
    size = { '(monitor_w*0.92)', '(monitor_h*0.92)' },
    center = true,
})
hl.window_rule({
    match = { class = '^localsend$' },
    size = { '(monitor_w*0.70)', '(monitor_h*0.70)' },
    center = true,
})
hl.window_rule({
    match = { title = '^(htop|yazi|Downloads)$' },
    size = { '(monitor_w*0.75)', '(monitor_h*0.75)' },
    center = true,
})
hl.window_rule({
    match = { class = '^(org.pwmt.zathura|imv)$' },
    size = { '(monitor_w*0.50)', '(monitor_h*0.92)' },
})
hl.window_rule({ match = { class = '^xdg-desktop-portal-gtk$' }, center = true })

hl.layer_rule({ match = { namespace = 'waybar' }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = 'rofi' }, blur = true })
