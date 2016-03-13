--==============================================================================
--          File: init.lua
--        Author: Pedro Ferrari
--       Created: 13 Mar 2016
-- Last Modified: 13 Mar 2016
--   Description: My Hammerspoon config file
--==============================================================================
-- Note: we can use a combination of Apptivate, Spectacle and Hyperswitch if we
-- don't want to use Hammerspoon
-- See https://github.com/exark/dotfiles/blob/master/.hammerspoon/init.lua
--
-- Reload (auto) hotkey script
hs.hotkey.bind({"ctrl", "cmd"}, "A", function()
  hs.reload()
  hs.alert.show("Hammerspoon config was reloaded.")
end)

-- Don't perform animations when resizing
hs.window.animationDuration = 0

-- Resize window for chunk of screen:
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
hs.hotkey.bind({"ctrl", "cmd"}, "up", function()
                resize_win(0,0,1,0.5) end) -- top
hs.hotkey.bind({"ctrl", "cmd"}, "down", function()
                resize_win(0,0.5,1,0.5) end) -- bottom
hs.hotkey.bind({"cmd"}, "up", function()
                resize_win(0,0,1,1) end) -- full
hs.hotkey.bind({"ctrl", "cmd"}, "1", function()
                resize_win(0,0,0.5,0.5) end) -- Top left quarter
hs.hotkey.bind({"ctrl", "cmd"}, "2", function()
                resize_win(0,0.5,0.5,0.5) end) -- Bottom left quarter
hs.hotkey.bind({"ctrl", "cmd"}, "3", function()
                resize_win(0.5,0,0.5,0.5) end) -- Top right quarter
hs.hotkey.bind({"ctrl", "cmd"}, "4", function()
                resize_win(0.5,0.5,0.5,0.5) end) -- Bottom right quarter
hs.hotkey.bind({"ctrl", "cmd"}, "5", function()
                resize_win(0.25,0.25,0.5,0.5) end) -- Center
-- TODO: Resize window (up and down)

-- Move window to next/ previous monitor
-- Get list of screens and refresh that list whenever screens are plugged or
-- unplugged:
local screens = hs.screen.allScreens()
local screenwatcher = hs.screen.watcher.new(function()
                                            screens = hs.screen.allScreens()
                                            end)
screenwatcher:start()

-- Checks to make sure monitor exists, if not moves to last monitor that exists
function moveToMonitor(x)
	local win = hs.window.focusedWindow()
	local newScreen = nil
	while not newScreen do
		newScreen = screens[x]
		x = x-1
	end

	win:moveToScreen(newScreen)
end
hs.hotkey.bind({"ctrl", "cmd"},"right",
                function() moveToMonitor(2) end)
hs.hotkey.bind({"ctrl", "cmd"},"left",
                function() moveToMonitor(1) end)


-- Run or activate applications
hs.hotkey.bind({"ctrl", "cmd"}, "v", function()
                hs.application.launchOrFocus("Macvim") end)
hs.hotkey.bind({"ctrl", "cmd"}, "c", function()
                hs.application.launchOrFocus("Iterm") end)
hs.hotkey.bind({"ctrl", "cmd"}, "f", function()
                hs.application.launchOrFocus("Firefox") end)
hs.hotkey.bind({"ctrl", "cmd"}, "X", function()
                hs.application.launchOrFocus("Microsoft Excel") end)
