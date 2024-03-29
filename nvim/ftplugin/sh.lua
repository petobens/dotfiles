local overseer = require('overseer')
local utils = require('telescope.utils')

-- Options
vim.opt_local.textwidth = 90

-- Running
local _parse_qf = function(qf_title, active_window_id)
    local current_qf = vim.fn.getqflist()
    local new_qf = {}
    for _, v in pairs(current_qf) do
        if v.valid > 0 or v.text ~= '' then
            if v.lnum > 0 then
                v.type = 'E'
            end
            table.insert(new_qf, v)
        end
    end
    if next(new_qf) ~= nil then
        vim.fn.setqflist({}, ' ', { items = new_qf, title = qf_title })
        vim.cmd('copen')
        vim.fn.win_gotoid(active_window_id)
    end
end

local function run_overseer()
    local current_win_id = vim.fn.win_getid()
    vim.cmd('silent noautocmd update')
    overseer.run_template({ name = 'run_sh' }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            _parse_qf(task.metadata.run_cmd, current_win_id)
        end)
    end)
end

local run_toggleterm = function()
    vim.cmd('silent noautocmd update')
    vim.cmd(
        string.format(
            'TermExec cmd="%s %s"',
            'bash',
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        )
    )
end

local run_tmux_pane = function()
    if vim.env.TMUX == nil then
        return
    end
    local cwd = utils.buffer_dir()
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
    local sh_cmd = '"bash ' .. fname .. [[; read -p ''"]]
    vim.cmd('silent! !tmux new-window -c ' .. cwd .. ' -n ' .. fname .. ' ' .. sh_cmd)
end

-- Mappings
vim.keymap.set({ 'n', 'i' }, '<F7>', run_overseer, { buffer = true })
vim.keymap.set({ 'n', 'i' }, '<F5>', run_tmux_pane, { buffer = true })
vim.keymap.set('n', '<Leader>rf', run_toggleterm, { buffer = true })
vim.keymap.set('n', '<Leader>ri', run_toggleterm, { buffer = true })
