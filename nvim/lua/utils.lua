local M = {}

function M.mk_non_dir(directory)
    local dir = directory or vim.fn.expand('%:p:h')
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
    end
end

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

function M.get_selection()
    local text
    if vim.fn.mode() == 'v' then
        vim.cmd('noautocmd normal! "vy"')
        text = vim.fn.getreg('v')
        vim.fn.setreg('v', {})
        text = string.gsub(text, '\n', '')
    else
        text = vim.fn.expand('<cWORD>')
    end
    return text
end

M.icons = {
    -- Running
    error = '',
    warning = '',
    info = '',
    hint = '',
    running = '󰜎',
    -- Folding
    fold_open = '',
    fold_close = '',
}

return M
