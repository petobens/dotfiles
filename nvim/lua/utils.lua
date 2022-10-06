local M = {}

function M.keymap(mode, lhs, rhs, opts)
    return vim.keymap.set(
        mode,
        lhs,
        rhs,
        vim.tbl_extend('keep', opts or {}, {
            remap = false,
            nowait = true,
            silent = true,
        })
    )
end

function M.border(hl_name)
    return {
        { '╭', hl_name },
        { '─', hl_name },
        { '╮', hl_name },
        { '│', hl_name },
        { '╯', hl_name },
        { '─', hl_name },
        { '╰', hl_name },
        { '│', hl_name },
    }
end

function _G.put(...)
    local objects = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(objects, vim.inspect(v))
    end

    print(table.concat(objects, '\n'))
    return ...
end

return M
