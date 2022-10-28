local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'mwe', dscr = 'MWE template' },
        fmta(
            [[
      \documentclass{<>}
      \begin{document}
          <>
      \end{document}
    ]],
            {
                i(1, 'article'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
}, {}
