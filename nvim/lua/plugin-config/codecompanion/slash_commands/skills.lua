local skills_picker = require('plugin-config.codecompanion.pickers.skills')

local M = {}

function M.skills(chat)
    skills_picker.browse(function(skill)
        if chat and chat.bufnr and vim.api.nvim_buf_is_valid(chat.bufnr) then
            local win = vim.fn.bufwinid(chat.bufnr)
            if win ~= -1 then
                vim.api.nvim_set_current_win(win)
            end
        end
        vim.api.nvim_put({ skill.name }, 'c', true, true)
    end)
end

return M
