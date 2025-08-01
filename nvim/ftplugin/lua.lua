local overseer = require('overseer')

-- Options
vim.opt_local.textwidth = 90

-- Running
local function _parse_qf(qf_title, active_window_id)
    local current_qf = vim.fn.getqflist()
    local new_qf = {}
    for _, v in ipairs(current_qf) do
        if v.valid > 0 or v.text ~= '' then
            if v.lnum > 0 then
                v.type = 'E'
            end
            table.insert(new_qf, v)
        end
    end
    if #new_qf > 0 then
        vim.fn.setqflist({}, ' ', { items = new_qf, title = qf_title })
        vim.cmd.copen()
        vim.api.nvim_set_current_win(active_window_id)
    end
end

local function run_overseer()
    local current_win_id = vim.api.nvim_get_current_win()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    overseer.run_template({ name = 'run_lua' }, function(task)
        vim.cmd.cclose()
        task:subscribe('on_complete', function()
            _parse_qf(task.metadata.run_cmd, current_win_id)
        end)
    end)
end

local function run_toggleterm()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.cmd(
        string.format('TermExec cmd="%s %s"', 'nvim -l', vim.api.nvim_buf_get_name(0))
    )
end

local function run_tmux_pane()
    if not vim.env.TMUX then
        return
    end
    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local fname = vim.fs.basename(vim.api.nvim_buf_get_name(0))
    local sh_cmd = string.format('nvim -l %s; read -p ""', fname)
    vim.cmd({
        cmd = '!',
        args = { 'tmux', 'new-window', '-c', cwd, '-n', fname, sh_cmd },
        mods = { silent = true },
    })
end

vim.api.nvim_create_user_command('RunVisualLua', function()
    vim.cmd('normal ') -- leave visual mode to set <,> marks
    local lines = vim.fn.getline(vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2])
    vim.cmd.lua(table.concat(lines, ' '))
end, { range = true })

-- Mappings
vim.keymap.set({ 'n', 'i' }, '<F7>', run_overseer, { buffer = true })
vim.keymap.set({ 'n', 'i' }, '<F5>', run_tmux_pane, { buffer = true })
vim.keymap.set('n', '<Leader>rf', run_toggleterm, { buffer = true })
vim.keymap.set('n', '<Leader>rl', function()
    vim.cmd.lua(vim.api.nvim_get_current_line())
end, { buffer = true })
vim.keymap.set('n', '<Leader>ri', function()
    vim.cmd.update()
    vim.cmd.luafile('%')
end, { silent = false, buffer = true })
vim.keymap.set('v', '<Leader>ri', ':RunVisualLua<CR>', { buffer = true })
