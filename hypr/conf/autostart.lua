-- luacheck: globals hl

local scripts = os.getenv('HOME') .. '/.config/hypr/scripts/'

hl.on('hyprland.start', function()
    hl.exec_cmd('brightnessctl set 30%')
    if #hl.get_monitors() == 1 or not hl.get_monitor('Virtual-1') then
        -- Hyprpaper cannot allocate buffers with QEMU's software multi-display GPU
        hl.exec_cmd('hyprpaper')
    end

    hl.exec_cmd('waybar')
    hl.exec_cmd('mako')
    hl.exec_cmd('hypridle')
    hl.exec_cmd('systemctl --user start hyprpolkitagent')
    hl.exec_cmd('voxtype')
    hl.exec_cmd('udiskie')
    hl.exec_cmd(scripts .. 'battery_monitor')

    -- Clipboard history and persistence after the source window closes
    hl.exec_cmd('wl-clip-persist --clipboard regular')
    hl.exec_cmd('wl-paste --type text --watch ' .. scripts .. 'clipboard_store')
    hl.exec_cmd('wl-paste --type image --watch ' .. scripts .. 'clipboard_store')
end)
