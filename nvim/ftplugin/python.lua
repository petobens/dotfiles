local u = require('utils')
local builtin = require('telescope.builtin')
local utils = require('telescope.utils')

-- Compiling
local run_tmux_pane = function()
    if vim.env.TMUX == nil then
        return
    end
    local cwd = utils.buffer_dir()
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
    local sh_cmd = '"python ' .. fname .. '; exec bash"'
    vim.cmd('silent! !tmux new-window -c ' .. cwd .. ' -n ' .. fname .. ' ' .. sh_cmd)
end

u.keymap('n', '<F5>', function()
    run_tmux_pane()
end, { buffer = true })

-- Debugging
local add_breakpoint = function()
    local save_cursor = vim.fn.getcurpos()
    local current_line = vim.fn.line('.')
    local breakpoint_line = current_line - 1
    local indent_length = vim.fn.match(vim.fn.getline(current_line), '\\w')
    local bp_statement = string.rep(' ', indent_length) .. 'breakpoint()'
    vim.fn.append(breakpoint_line, bp_statement)
    vim.cmd('silent noautocmd update')
    vim.fn.setpos('.', save_cursor)
end

local remove_breakpoints = function()
    local save_cursor = vim.fn.getcurpos()
    vim.cmd('g/breakpoint()/d')
    vim.cmd('silent noautocmd update')
    vim.fn.setpos('.', save_cursor)
end

local list_breakpoints = function(local_buffer)
    local opts = {
        use_regex = true,
        search = 'breakpoint()',
    }
    if local_buffer == true then
        local buf_name = vim.api.nvim_buf_get_name(0)
        opts = vim.tbl_extend('keep', opts, {
            results_title = buf_name,
            search_dirs = { buf_name },
        })
    else
        local buffer_dir = utils.buffer_dir()
        opts = vim.tbl_extend('keep', opts, {
            cwd = buffer_dir,
            results_title = buffer_dir,
        })
    end
    builtin.grep_string(opts)
end

u.keymap('n', '<Leader>bp', add_breakpoint, { buffer = true })
u.keymap('n', '<Leader>rb', remove_breakpoints, { buffer = true })
u.keymap('n', '<Leader>lb', function()
    list_breakpoints(true)
end, { buffer = true })
u.keymap('n', '<Leader>lB', function()
    list_breakpoints(false)
end, { buffer = true })
