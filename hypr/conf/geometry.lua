-- luacheck: globals hl

local M = { border_size = 2 }

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

-- Monitor geometry
local function work_area(monitor)
    local reserved = monitor.reserved
    return {
        x = monitor.x + reserved.left,
        y = monitor.y + reserved.top,
        width = monitor.width / monitor.scale - reserved.left - reserved.right,
        height = monitor.height / monitor.scale - reserved.top - reserved.bottom,
    }
end

local function usable_bounds(monitor)
    local area = work_area(monitor)
    local inset = M.border_size
    return area.x + inset,
        area.y + inset,
        area.x + area.width - inset,
        area.y + area.height - inset
end

-- Fractional placement
function M.place(window, placement, monitor)
    local area = work_area(monitor or window.monitor)
    local inset = M.border_size
    hl.dispatch(hl.dsp.window.resize({
        x = area.width * placement.width - inset * 2,
        y = area.height * placement.height - inset * 2,
        window = window,
    }))
    hl.dispatch(hl.dsp.window.move({
        x = area.x + area.width * placement.x + inset,
        y = area.y + area.height * placement.y + inset,
        window = window,
    }))
end

function M.capture(window, monitor)
    local area = work_area(monitor or window.monitor)
    local inset = M.border_size
    local width = math.min((window.size.x + inset * 2) / area.width, 1)
    local height = math.min((window.size.y + inset * 2) / area.height, 1)
    return {
        x = clamp((window.at.x - area.x - inset) / area.width, 0, 1 - width),
        y = clamp((window.at.y - area.y - inset) / area.height, 0, 1 - height),
        width = width,
        height = height,
    }
end

-- Work-area enforcement
function M.constrain(window, monitor)
    if not window.floating or window.fullscreen ~= 0 then
        return
    end

    local min_x, min_y, max_x, max_y = usable_bounds(monitor or window.monitor)
    local width = math.min(window.size.x, max_x - min_x)
    local height = math.min(window.size.y, max_y - min_y)
    local x = clamp(window.at.x, min_x, max_x - width)
    local y = clamp(window.at.y, min_y, max_y - height)

    if width ~= window.size.x or height ~= window.size.y then
        hl.dispatch(hl.dsp.window.resize({ x = width, y = height, window = window }))
    end
    if x ~= window.at.x or y ~= window.at.y then
        hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = window }))
    end
end

function M.constrain_all()
    for _, window in ipairs(hl.get_windows()) do
        M.constrain(window)
    end
end

function M.resize(window, delta)
    local min_x, min_y, max_x, max_y = usable_bounds(window.monitor)
    local desired_x = window.at.x + delta.x
    local desired_y = window.at.y + delta.y
    local desired_right = desired_x + math.max(1, window.size.x + delta.width)
    local desired_bottom = desired_y + math.max(1, window.size.y + delta.height)
    local x = clamp(desired_x, min_x, max_x - 1)
    local y = clamp(desired_y, min_y, max_y - 1)
    local right = clamp(desired_right, x + 1, max_x)
    local bottom = clamp(desired_bottom, y + 1, max_y)

    hl.dispatch(hl.dsp.window.resize({
        x = right - x,
        y = bottom - y,
        window = window,
    }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = window }))
end

return M
