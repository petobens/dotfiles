local M = {}

function M.keymap(mode, lhs, rhs, opts)
    return vim.api.nvim_set_keymap(mode, lhs, rhs, vim.tbl_extend('keep', opts or {}, {
        nowait = true,
        silent = true,
        noremap = true,
    }))
end

function M.buf_keymap(buf, mode, lhs, rhs, opts)
    return vim.api.nvim_buf_set_keymap(buf, mode, lhs, rhs, vim.tbl_extend('keep', opts or {}, {
        nowait = true,
        silent = true,
        noremap = true,
    }))
end

function M.unmap(mode, lhs)
    return vim.api.nvim_del_keymap(mode, lhs)
end

function M.opt(scope, key, value)
    vim[scope][key] = value
    if scope ~= 'o' then
        vim['o'][key] = value
    end
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
