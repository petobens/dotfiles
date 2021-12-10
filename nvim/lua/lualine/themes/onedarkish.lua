local c = require('onedarkpro').get_colors()

local onedarkish = {}

onedarkish.normal = {
	a = {fg = c.bg, bg = c.green, gui = 'bold'},
	b = {fg = c.fg, bg = c.special_grey},
	c = {fg = c.fg, bg = c.color_column},
	x = {fg = '#828997', bg = c.color_column},
	y = {fg = c.fg, bg = c.special_grey},
	z = {fg = '#303030', bg = '#d0d0d0'},
}

onedarkish.insert = {
	a = {fg = c.bg, bg = c.light_blue, gui = 'bold'},
}

onedarkish.visual = {
	a = {fg = c.bg, bg = c.orange, gui = 'bold'},
}

onedarkish.command = {
	a = {fg = c.bg, bg = c.blue, gui = 'bold'},
}

onedarkish.terminal = {
	a = {fg = c.bg, bg = c.cyan, gui = 'bold'},
}

onedarkish.replace = {
	a = {fg = c.bg, bg = c.purple, gui = 'bold'},
}

onedarkish.inactive = {
	a = {fg = '#5c6370', bg = c.color_column},
	b = {fg = '#5c6370', bg = c.color_column},
	c = {fg = '#5c6370', bg = c.color_column},
	x = {fg = '#5c6370', bg = c.color_column},
	y = {fg = '#5c6370', bg = c.color_column},
	z = {fg = '#5c6370', bg = c.color_column},
}

onedarkish.tabline = {
    tabsel = {fg = c.bg, bg = c.light_blue, gui = 'bold'},
    tabmod = {fg = c.bg, bg = c.red, gui = 'bold'},
    tabvis = {fg = c.white, bg = c.special_grey},
    tabhid = {fg = c.gray, bg = c.cursor_grey},
    tabmod_unsel = {fg = c.bg, bg = c.orange, gui = 'bold'},
}

return onedarkish
