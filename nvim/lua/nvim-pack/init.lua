local M = {}
local dashboard = require('nvim-pack.dashboard')
local manager = require('nvim-pack.manager')

function M.setup(specs)
    dashboard.setup(manager)
    manager.setup(specs)
end

return M
