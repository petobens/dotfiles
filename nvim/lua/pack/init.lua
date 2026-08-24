local dashboard = require('pack.dashboard')
local manager = require('pack.manager')

return {
    log = dashboard.log,
    open = dashboard.open,
    setup = manager.setup,
    sync = dashboard.sync,
}
