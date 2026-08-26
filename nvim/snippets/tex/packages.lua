local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'll', dscr = '[L]aTeX [l]istings' },
        fmta(
            [[
      \begin{lstlisting}
        <><>
      \end{lstlisting}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mt', dscr = '[M]in[t]ed' },
        fmta(
            [[
      \begin{minted}{<>}
        <><>
      \end{minted}
    ]],
            {
                i(1, 'python'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mtc', dscr = '[M]in[t]ed with [c]aptions' },
        fmta(
            [[
      \begin{listing}[H]
        \begin{minted}{<>}
            <><>
        \end{minted}
        \caption{<>}
      \end{listing}
    ]],
            {
                i(1, 'python'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'td', wordTrig = false, dscr = '[T]o[d]o' },
        fmta(
            [[
        \todo{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
}, {}
