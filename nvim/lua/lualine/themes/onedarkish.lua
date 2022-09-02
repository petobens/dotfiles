-- For this to work we need to ensure that lualine loads after onedarkpro
local c = require('onedarkpro').get_colors()

local onedarkish = {}

onedarkish.normal = {
    a = { fg = c.bg, bg = c.green, gui = 'bold' },
    b = { fg = c.fg, bg = c.special_grey },
    c = { fg = c.fg, bg = c.color_column },
    x = { fg = '#828997', bg = c.color_column },
    y = { fg = c.fg, bg = c.special_grey },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.insert = {
    a = { fg = c.bg, bg = c.light_blue, gui = 'bold' },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.visual = {
    a = { fg = c.bg, bg = c.orange, gui = 'bold' },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.command = {
    a = { fg = c.bg, bg = c.blue, gui = 'bold' },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.terminal = {
    a = { fg = c.bg, bg = c.cyan, gui = 'bold' },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.replace = {
    a = { fg = c.bg, bg = c.purple, gui = 'bold' },
    z = { fg = '#303030', bg = '#d0d0d0' },
}

onedarkish.inactive = {
    a = { fg = '#5c6370', bg = c.color_column },
    b = { fg = '#5c6370', bg = c.color_column },
    c = { fg = '#5c6370', bg = c.color_column },
    x = { fg = '#5c6370', bg = c.color_column },
    y = { fg = '#5c6370', bg = c.color_column },
    z = { fg = '#5c6370', bg = c.color_column },
}

onedarkish.tabline = {
    hidden = { fg = c.gray, bg = c.cursor_grey },
    modified = { fg = c.bg, bg = c.red, gui = 'bold' },
    modified_unselected = { fg = c.bg, bg = c.orange, gui = 'bold' },
    selected = { fg = c.bg, bg = c.light_blue, gui = 'bold' },
    visible = { fg = c.white, bg = c.special_grey },
}

return onedarkish
