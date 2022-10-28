local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'art', dscr = 'Article' },
        fmta(
            [[
            @Article{<>,
                author  = {<>},
                title   = {<>},
                journal = {<>},
                year    = {<>},
                volume  = {<>},
                number  = {<>},
                pages   = {<>}
            }
            ]],
            {
                i(1),
                i(2, 'names separated by "and"'),
                i(3, 'title'),
                i(4, 'journal name'),
                i(5, 'year'),
                i(6, 'volume number'),
                i(7, 'number'),
                i(8, 'page range'),
            }
        ),
        { condition = line_begin }
    ),
}, {}
