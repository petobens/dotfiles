-- luacheck: globals ps cx

local function setup()
    ps.sub('ind-sort', function(options)
        local cwd = tostring(cx.active.current.cwd)
        if
            cwd == os.getenv('HOME') .. '/Downloads'
            or cwd == os.getenv('HOME') .. '/Pictures/Screenshots'
        then
            options.by, options.reverse, options.dir_first = 'mtime', true, true
        else
            options.by, options.reverse, options.dir_first = 'natural', false, true
        end
        return options
    end)
end

return { setup = setup }
