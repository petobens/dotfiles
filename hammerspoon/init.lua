--==============================================================================
--          File: init.lua
--        Author: Pedro Ferrari
--       Created: 13 Mar 2016
-- Last Modified: 15 Aug 2016
--   Description: My Hammerspoon config file
--==============================================================================
-- To use the dev version, download master from git and then run `sh rebuild.sh`
-- following:
-- https://github.com/Hammerspoon/hammerspoon/blob/master/CONTRIBUTING.md#making-frequent-local-rebuilds-more-convenient

-- Preamble {{{

-- Modifier shortcuts
local cmd_ctrl = {"ctrl", "cmd"}

-- Reload (auto) hotkey script
hs.hotkey.bind(cmd_ctrl, "a", function()
  hs.reload()
  hs.alert.show("Hammerspoon config was reloaded.")
end)

-- Don't perform animations when resizing
hs.window.animationDuration = 0

-- Get list of screens and refresh that list whenever screens are plugged or
-- unplugged i.e initiate watcher
local screens = hs.screen.allScreens()
local screenwatcher = hs.screen.watcher.new(function()
                                                screens = hs.screen.allScreens()
                                            end)
screenwatcher:start()

-- }}}
-- Window handling {{{

-- Resize window for chunk of screen (this deprecates Spectable)
-- For x and y: use 0 to expand fully in that dimension, 0.5 to expand halfway
-- For w and h: use 1 for full, 0.5 for half
function resize_win(x, y, w, h)
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + (max.w * x)
	f.y = max.y + (max.h * y)
	f.w = max.w * w
	f.h = max.h * h
	win:setFrame(f)
end
hs.hotkey.bind({"cmd"}, "left", function()
                resize_win(0,0,0.5,1) end) -- left
hs.hotkey.bind({"cmd"}, "right", function()
                resize_win(0.5,0,0.5,1) end) -- right
hs.hotkey.bind(cmd_ctrl, "up", function()
                resize_win(0,0,1,0.5) end) -- top
hs.hotkey.bind(cmd_ctrl, "down", function()
                resize_win(0,0.5,1,0.5) end) -- bottom
hs.hotkey.bind({"cmd"}, "up", function()
                resize_win(0,0,1,1) end) -- full
hs.hotkey.bind(cmd_ctrl, "1", function()
                resize_win(0,0,0.5,0.5) end) -- Top left quarter
hs.hotkey.bind(cmd_ctrl, "2", function()
                resize_win(0,0.5,0.5,0.5) end) -- Bottom left quarter
hs.hotkey.bind(cmd_ctrl, "3", function()
                resize_win(0.5,0,0.5,0.5) end) -- Top right quarter
hs.hotkey.bind(cmd_ctrl, "4", function()
                resize_win(0.5,0.5,0.5,0.5) end) -- Bottom right quarter
hs.hotkey.bind(cmd_ctrl, "5", function()
                resize_win(0.25,0.25,0.5,0.5) end) -- Center

-- (Expand) to full screen (we use OSX default Cmd + F to open finder)
hs.hotkey.bind(cmd_ctrl, "e", function()
        local win = hs.window.focusedWindow()
        if win ~= nil then
            win:setFullScreen(not win:isFullScreen())
        end
    end)

-- Change window width (setting the grid first)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0
hs.grid.GRIDWIDTH = 10
hs.grid.GRIDHEIGHT = 2
hs.hotkey.bind(cmd_ctrl, "-", function()
    hs.grid.resizeWindowThinner(hs.window.focusedWindow())
end)
hs.hotkey.bind(cmd_ctrl, "=", function()
    hs.grid.resizeWindowWider(hs.window.focusedWindow())
end)

-- Expose (show thumbnails of open windows with a hint)
hs.expose.ui.otherSpacesStripWidth = 0  -- I don't use other spaces
hs.expose.ui.highlightThumbnailStrokeWidth = 5
hs.expose.ui.textSize = 30
hs.expose.ui.nonVisibleStripWidth = 0.2
hs.expose.ui.nonVisibleStripBackgroundColor = {0.08, 0.08, 0.08}
hs.hotkey.bind(cmd_ctrl, "j", function()
                hs.expose.new():toggleShow() end)

-- Window switcher (deprecates Hyperswitch)
hs.window.switcher.ui.showSelectedThumbnail = false
hs.window.switcher.ui.showTitles = false
hs.window.switcher.ui.textSize = 12
hs.window.switcher.ui.thumbnailSize = 180
hs.window.switcher.ui.backgroundColor = {0.2, 0.2, 0.2, 0.3} -- Greyish
hs.window.switcher.ui.titleBackgroundColor = {0, 0, 0, 0} -- Transparent
hs.window.switcher.ui.textColor = {0, 0, 0} -- Black
-- TODO: Show switcher on active screen
-- TODO: fix text paddling
switcher = hs.window.switcher.new(
                hs.window.filter.new():setCurrentSpace(true):setDefaultFilter{})
hs.hotkey.bind("alt", "tab", function() switcher:next() end)

-- }}}
-- Multiple monitors handling {{{

-- Move window to next/previous monitor (checks to make sure monitor exists, if
-- not moves to last monitor that exists)
function moveToMonitor(x)
	local win = hs.window.focusedWindow()
	local newScreen = nil
	while not newScreen do
		newScreen = screens[x]
		x = x - 1
	end
	win:moveToScreen(newScreen)

    -- Also move the mouse to center of next screen
    local center = hs.geometry.rectMidPoint(newScreen:fullFrame())
    hs.mouse.setAbsolutePosition(center)
end
--  At work we have the MacBook monitor ('Color LCD') on the right and the big
--  monitor on the left, at home the other way around:
hs.hotkey.bind(cmd_ctrl,"right", function()
    if hs.screen('Color LCD'):toEast() then
        moveToMonitor(2)
    else
        moveToMonitor(1)
    end
end)
hs.hotkey.bind(cmd_ctrl,"left", function()
    if hs.screen('Color LCD'):toWest() then
        moveToMonitor(2)
    else
        moveToMonitor(1)
    end
end)


-- Switch focus and mouse to the next monitor
function windowInScreen(screen, win) -- Check if a window belongs to a screen
    return win:screen() == screen
end
function focusNextScreen()
    -- Get next screen (and its center point) using current mouse position
    -- local next_screen = hs.window.focusedWindow():screen():next()
    local next_screen = hs.mouse.getCurrentScreen():next()
    local center = hs.geometry.rectMidPoint(next_screen:fullFrame())

    -- Find windows within this next screen, ordered from front to back.
    windows = hs.fnutils.filter(hs.window.orderedWindows(),
                                hs.fnutils.partial(windowInScreen, next_screen))

    -- Move the mouse to the center of the other screen
    hs.mouse.setAbsolutePosition(center)

    --  Set focus on front-most application window or bring focus to desktop if
    --  no windows exists
    if #windows > 0 then
        windows[1]:focus()
    else
        hs.window.desktop():focus()
        -- In this case also do a click to activate menu bar
        hs.eventtap.leftClick(hs.mouse.getAbsolutePosition())
    end
end
hs.hotkey.bind({"alt"}, "§", focusNextScreen)
hs.hotkey.bind({"alt"}, "`", focusNextScreen)

-- }}}
-- Run or activate app {{{

hs.hotkey.bind(cmd_ctrl, "i", function()
                hs.application.launchOrFocus("Firefox") end)
hs.hotkey.bind(cmd_ctrl, "x", function()
                hs.application.launchOrFocus("Microsoft Excel") end)
hs.hotkey.bind(cmd_ctrl, "w", function()
                hs.application.launchOrFocus("Microsoft Word") end)
hs.hotkey.bind(cmd_ctrl, "g", function()
                hs.application.launchOrFocus("Giphy Capture") end)
hs.hotkey.bind(cmd_ctrl, "s", function()
                hs.application.launchOrFocus("Skype") end)
hs.hotkey.bind(cmd_ctrl, "l", function()
                hs.application.launchOrFocus("Slack") end)
hs.hotkey.bind(cmd_ctrl, "p", function()
                hs.application.launchOrFocus("Skim") end)
hs.hotkey.bind(cmd_ctrl, "f", function()
                hs.application.launchOrFocus("Finder") end)
hs.hotkey.bind(cmd_ctrl, "t", function()
                hs.application.launchOrFocus("Thunderbird") end)
hs.hotkey.bind(cmd_ctrl, "u", function()
                hs.application.launchOrFocus("Vuze") end)
hs.hotkey.bind(cmd_ctrl, "m", function()
                hs.application.launchOrFocus("Spotify") end)
hs.hotkey.bind(cmd_ctrl, "d", function()
                hs.execute("open ~/Downloads/") end)

function Tmux()
    -- Launch or open iTerm
    hs.application.launchOrFocus("iTerm")

    -- Open tmux (loading tmux config file)
    local win_title = hs.window.focusedWindow():title()
    hs.timer.usleep(120000) -- Wait for title to update
    if not string.match(win_title:lower(), "tmux") then
        -- Use tmux alias defined in bash_profile
        hs.eventtap.keyStrokes("tm")
        hs.eventtap.keyStroke({""}, "return")
    end
end
hs.hotkey.bind(cmd_ctrl, "c", Tmux)


-- }}}
-- Vim {{{

-- To run or activate Macvim
-- hs.hotkey.bind(cmd_ctrl, "v", function()
                -- hs.application.launchOrFocus("Macvim") end)

-- Activate Vim inside of tmux inside of iTerm
function VimTmux()
    -- Launch or open iTerm
    -- FIXME: Wait for iTerm to open properly
    hs.application.launchOrFocus("iTerm")

    -- Check if there is a tab with tmux (do this only for 5 tabs since we
    -- rarely open more than 5 tabs in iTerm) and create one if there is not
    local i = 0
    while i < 5 do
        local win_title = hs.window.focusedWindow():title()
        if string.match(win_title:lower(), "tmux") then
            break
        else
            hs.eventtap.keyStroke({"cmd","shift"}, "]")
            -- Wait for the win title to update (this is necessary!)
            hs.timer.usleep(120000) -- Microseconds (0.12 seconds)
        end
        i = i + 1
        -- If after 5 tries there is not tmux tab then create a tmux tab and
        -- attach to an existing session named petobens (unless such session
        -- doesn't exit in which case create one)
        if i == 5 then
            -- If our current window is a bash console then create tmux there
            -- otherwise open a new tab.
            -- Note: since we use powerline we might be inside a bash terminal
            -- but the window title will show python until powerline finishes
            -- loading. Therefore we must wait a bit before checking the window
            -- title.
            hs.timer.doAfter(0.7, function()
                local current_win_title = hs.window.focusedWindow():title()
                if not string.match(current_win_title:lower(), "bash") then
                    hs.eventtap.keyStroke({"cmd"}, "t")
                end
            end)
            hs.eventtap.keyStrokes("tmux new -A -s petobens")
            hs.eventtap.keyStroke({""}, "return")

            -- Wait for tmux to open
            hs.timer.usleep(1500001) -- Microseconds (1.5 second)
        end
    end

    -- Once inside of tmux try to select a window named Vim
    hs.eventtap.keyStroke({"ctrl"}, "a")
    hs.timer.usleep(120000) -- Wait to get into command mode
    hs.eventtap.keyStrokes(":select-window -t vim")
    hs.eventtap.keyStroke({""}, "return")


    -- We now check if the window or pane title contains Vim
    -- In order for this to work, iTerm window title must display tmux window
    -- titles. To do so, put the following in .tmux.conf:
        -- set -g set-titles on
        -- set-option -g set-titles-string "#{session_name} - #W"
    local j = 1
    while j < 3 do
        hs.timer.usleep(120000) -- Wait for window title to update
        local tmux_win_title = hs.window.focusedWindow():title()
        -- If the current pane/window is vim then break
        if string.match(tmux_win_title:lower(), "vim") then
            break
        else
            -- Go to the next pane
            hs.eventtap.keyStroke({"ctrl"}, "a")
            hs.timer.usleep(120000) -- Wait to get into command mode
            hs.eventtap.keyStrokes(":select-pane -t :.+")
            hs.eventtap.keyStroke({""}, "return")
        end
        j = j + 1
        if j == 3 then
            -- If none of the panes contained vim then if the current pane is a
            -- bash console open vim in it, otherwise open it in a new window
            local current_pane_title = hs.window.focusedWindow():title()
            if string.match(current_pane_title:lower(), "bash") then
                hs.eventtap.keyStrokes("vim")
                hs.eventtap.keyStroke({""}, "return")
            else
                hs.eventtap.keyStroke({"ctrl"}, "a")
                hs.timer.usleep(120000)
                hs.eventtap.keyStrokes(":new-window vim")
                hs.eventtap.keyStroke({""}, "return")
            end
        end
    end
end
hs.hotkey.bind(cmd_ctrl, "v", VimTmux)

-- Restart Vim (terminal) and load previous session
hs.hotkey.bind(cmd_ctrl, "r", function()
                hs.eventtap.keyStrokes(",kv")
                -- Since we are in tmux, once we exit we have bash prompt
                -- therefore we simply type vim again to restart it
                hs.timer.doAfter(0.7, function()
                                    hs.eventtap.keyStrokes("vim")
                                    hs.eventtap.keyStroke({""}, "return")
                                end)
                hs.timer.doAfter(1.5, function()
                                        hs.eventtap.keyStrokes(",ps") end)
                end)

-- }}}
-- Spotify and volume {{{

hs.hotkey.bind({"cmd", "shift"}, 't', function()
                                        hs.spotify.displayCurrentTrack() end)
hs.hotkey.bind({"cmd", "shift"}, 'p', function() hs.spotify.playpause() end)
hs.hotkey.bind({"cmd", "shift"}, 'j', function() hs.spotify.next() end)
hs.hotkey.bind({"cmd", "shift"}, 'k', function() hs.spotify.previous() end)

-- Volume control
hs.hotkey.bind({"cmd", "shift"}, '=', function()
    local audio_output = hs.audiodevice.defaultOutputDevice()
    if audio_output:muted() then
        audio_output:setMuted(false)
    end
    audio_output:setVolume(hs.audiodevice.current().volume + 5)
    hs.alert.closeAll()
    hs.alert.show("Volume level: " ..
                    tostring(math.floor(hs.audiodevice.current().volume)) ..
                    "%")
end)
hs.hotkey.bind({"cmd", "shift"}, '-', function()
    local audio_output = hs.audiodevice.defaultOutputDevice()
    audio_output:setVolume(hs.audiodevice.current().volume - 5)
    hs.alert.closeAll()
    hs.alert.show("Volume level: " ..
                    tostring(math.floor(hs.audiodevice.current().volume)) ..
                    "%")
end)
hs.hotkey.bind({"cmd", "shift"}, 'm', function()
    local audio_output = hs.audiodevice.defaultOutputDevice()
    if audio_output:muted() then
        audio_output:setMuted(false)
    else
        audio_output:setMuted(true)
    end
end)
hs.hotkey.bind({"cmd", "shift"}, 'v', function()
    local audio_output = hs.audiodevice.defaultOutputDevice()
    hs.alert.closeAll()
    hs.alert.show("Volume level: " ..
                    tostring(math.floor(hs.audiodevice.current().volume)) ..
                    "%")
end)

-- }}}
-- Toggle hidden files {{{

hs.hotkey.bind(cmd_ctrl, "h", function()
    hidden_status = hs.execute("defaults read com.apple.finder " ..
                                "AppleShowAllFiles")
    if hidden_status == "YES\n"  then
        hs.execute("defaults write com.apple.finder AppleShowAllFiles NO")
    else
        hs.execute("defaults write com.apple.finder AppleShowAllFiles YES")
    end
    hs.execute("killall Finder")
end)

-- }}}
-- Active window screenshot {{{

hs.hotkey.bind({"shift", "cmd"}, "5", function()
                local image = hs.window.focusedWindow():snapshot()
                local current_date = os.date("%Y-%m-%d")
                local current_time = os.date("%H.%M.%S")
                local screenshot_dir = os.getenv("HOME") ..
                                        "/Pictures/Screenshots/"
                local filename = screenshot_dir .. "Screen Shot " ..
                                current_date .. " at " .. current_time .. ".png"
                image:saveToFile(filename)
                hs.alert("Screenshot saved as " .. filename)
            end)

-- }}}
-- Miscellaneous {{{

-- Lockscreen
hs.hotkey.bind({"shift", "cmd"}, "l", function()
                hs.caffeinate.lockScreen()
                end)

-- TODO: Shutdown, restart and remap capslock key to TAB (we already disabled it
-- from System Preferences)
hs.hotkey.bind({"shift", "cmd"}, "s", function()
                hs.eventtap.event.newSystemKeyEvent('EJECT', true):setFlags({ctrl = true}):post()
                end)
-- hs.hotkey.bind({"shift", "cmd"}, "r", function()
                -- hs.caffeinate.restartSystem() end)

-- Until the following works we can use ctrl+eject to ask for confirmation
function YesNoDialogBox(ActionFunc)
	test = hs.chooser.new(ActionFunc)
    test:rows(2)
    test:choices({{["text"] = "Yes", ["id"] = "yes"},
                {["text"] = "No", ["id"] = "no"}})
    test:show()
end
function RebootIfChoice(input)
    if input.id == "yes" then
        hs.alert("Your choice was: yes")
    else
        hs.alert("Your choice was: no")
    end
end
hs.hotkey.bind({"shift", "cmd"}, "r", function()
                                        YesNoDialogBox(RebootIfChoice) end)

-- Open trash folder and empty it (and then reactivate trash window)
hs.hotkey.bind({"cmd"}, "b", function() hs.execute("open ~/.Trash/") end)
hs.hotkey.bind(cmd_ctrl, "b", function() hs.execute("rm -rf ~/.Trash/*")
                                         hs.execute("open ~/.Trash/")
               end)

-- }}}
