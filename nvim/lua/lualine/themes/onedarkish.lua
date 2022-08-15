--- We cannot call `require('onedarkpro').get_colors()` here as per
--- https://github.com/olimorris/onedarkpro.nvim/pull/65#issuecomment-1214244012
--- So we copy the palette definition again
local palette = {
    bg = '#24272e',
    fg = '#abb2bf',

    -- Base colors
    black = '#24272e',
    blue = '#528bff',
    cyan = '#56b6c2',
    gray = '#5c6370',
    green = '#98c379',
    orange = '#d19a66',
    purple = '#c678dd',
    red = '#e06c75',
    white = '#abb2bf',
    yellow = '#e5c07b',
    none = 'NONE',

    -- Custom Colors
    cursor_grey = '#282c34',
    dark_red = '#be5046',
    light_blue = '#61afef',
    linenr_grey = '#4b5263',
    pmenu = '#333841',
    special_grey = '#3b4048',
    visual_grey = '#3e4452',
}
palette.comment_grey = palette.gray
palette.color_column = palette.cursor_grey
palette.cursorline = palette.cursor_grey
palette.highlight = palette.orange
local c = palette

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
