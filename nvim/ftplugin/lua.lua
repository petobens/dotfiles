local overseer = require('overseer')
local u = require('utils')

-- Options
vim.opt_local.formatoptions = 'jcql'

-- Running
local _parse_qf = function(qf_title, active_window_id)
    local current_qf = vim.fn.getqflist()
    local new_qf = {}
    for _, v in pairs(current_qf) do
        if v.valid > 0 or v.text ~= '' then
            table.insert(new_qf, v)
        end
    end
    if next(new_qf) ~= nil then
        vim.fn.setqflist({}, ' ', { items = new_qf, title = qf_title })
        vim.cmd('copen')
        vim.fn.win_gotoid(active_window_id)
    end
end

local function run_lua()
    local current_win_id = vim.fn.win_getid()
    vim.cmd('silent noautocmd update')
    overseer.run_template({ name = 'run_lua' }, function(task)
        vim.cmd('cclose')
        task:subscribe('on_complete', function()
            _parse_qf(task.metadata.run_cmd, current_win_id)
        end)
    end)
end

-- Mappings
u.keymap({ 'n', 'i' }, '<F7>', run_lua, { buffer = true })
u.keymap(
    'n',
    '<Leader>rf',
    '<Cmd>update<CR>:luafile %<CR>',
    { silent = false, buffer = true }
)
