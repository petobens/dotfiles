-- luacheck: globals hl

local geometry = require('conf.geometry')

local manually_placed_tag = 'manually-placed'
local work_area_maximized_tag = 'work-area-maximized'
local M = { work_area_maximized_tag = work_area_maximized_tag }

-- Helpers
local function mark_manually_placed(window)
    hl.dispatch(hl.dsp.window.tag({
        tag = '+' .. manually_placed_tag,
        window = window,
    }))
end

local function has_tag(window, name)
    for _, tag in ipairs(window.tags) do
        if tag == name or tag == name .. '*' then
            return true
        end
    end
    return false
end

-- Window state
function M.fills_work_area(window)
    return has_tag(window, work_area_maximized_tag)
        and not has_tag(window, manually_placed_tag)
end

-- Window geometry
function M.place(placement)
    return function()
        local window = hl.get_active_window()
        if not window then
            return
        end

        hl.dispatch(hl.dsp.window.fullscreen_state({
            internal = 0,
            client = 0,
            action = 'set',
            window = window,
        }))
        mark_manually_placed(window)
        hl.dispatch(hl.dsp.window.float({ action = 'enable', window = window }))
        geometry.place(window, placement)
    end
end

function M.resize(delta)
    return function()
        local window = hl.get_active_window()
        if not window then
            return
        end

        mark_manually_placed(window)
        geometry.resize(window, delta)
    end
end

function M.maximize()
    local window = hl.get_active_window()
    if not window then
        return
    end

    hl.dispatch(hl.dsp.window.tag({
        tag = '-' .. manually_placed_tag,
        window = window,
    }))
    hl.dispatch(hl.dsp.window.tag({
        tag = '+' .. work_area_maximized_tag,
        window = window,
    }))
    geometry.fill_work_area(window)
end

-- Preserve floating window geometry across monitors with different work areas
function M.move_to_monitor(kind, direction)
    return function()
        local source = hl.get_active_monitor()
        local target = hl.get_monitor(direction)
        if not source or not target or source == target then
            return
        end

        local windows
        if kind == 'window' then
            local window = hl.get_active_window()
            if not window then
                return
            end
            windows = { window }
        else
            windows = hl.get_workspace_windows(hl.get_active_workspace())
        end

        local geometries = {}
        for _, window in ipairs(windows) do
            if window.fullscreen == 0 then
                table.insert(geometries, {
                    window = window,
                    placement = geometry.capture(window, source),
                })
            end
        end

        if kind == 'window' then
            hl.dispatch(hl.dsp.window.move({ monitor = direction, follow = true }))
        else
            hl.dispatch(hl.dsp.workspace.move({ monitor = direction }))
        end

        for _, item in ipairs(geometries) do
            mark_manually_placed(item.window)
            geometry.place(item.window, item.placement, target)
        end
    end
end

-- Workspaces
function M.close_workspace()
    for _, window in ipairs(hl.get_workspace_windows(hl.get_active_workspace())) do
        hl.dispatch(hl.dsp.window.close({ window = window }))
    end
end

-- Restore the workspace's last focused window after switching to it
function M.switch_workspace(dispatcher)
    return function()
        local remembered = {}
        for _, workspace in ipairs(hl.get_workspaces()) do
            remembered[workspace.id] = workspace.last_window
        end
        hl.dispatch(dispatcher)
        local window = remembered[hl.get_active_workspace().id]
        if window then
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
    end
end

return M
