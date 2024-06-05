local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'toc', dscr = 'TOC' },
        fmta(
            [[
            ```{toctree}<><>

            <>
            ```
        ]],
            {
                c(1, { sn(nil, { t({ '', '' }), i(1, ':hidden:') }), t('') }),
                c(2, { sn(nil, { t({ '', '' }), i(1, ':caption: '), i(1) }), t('') }),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
}, {}
