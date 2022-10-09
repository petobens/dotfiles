local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    s({ trig = 'im', dscr = 'If main' }, {
        t({ "if __name__ == '__main__':", '\t' }),
        i(0),
    }),
}, {}
