local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta

local visual_selection = function(_, snip)
    return snip.env.TM_SELECTED_TEXT[1] or {}
end

return {

    -- Control flow
    s(
        { trig = 'im', dscr = 'If main' },
        fmta(
            [[
               if __name__ == '__main__':
                    <>
            ]],
            { i(0) }
        )
    ),
    s(
        { trig = 'bp', dscr = 'Breakpoint' },
        fmta(
            [[
            breakpoint()
        ]],
            {}
        )
    ),

    -- Logging
    s(
        { trig = 'bl', dscr = 'Basic logger' },
        fmta(
            [[
            logging.basicConfig(
                level=logging.<>,
                format='%(asctime)s-%(name)s-%(levelname)s: %(message)s',
                handlers=[logging.FileHandler('<>.log'), logging.StreamHandler()]
            )
        ]],
            { i(1, 'DEBUG'), i(2, 'logger_name') }
        )
    ),

    -- Linting
    s(
        { trig = 'pld', dscr = 'Pylint disable' },
        fmta(
            [[
            # pylint:disable=
        ]],
            {}
        )
    ),

    -- Pandas
    s(
        { trig = 'ipd', dscr = 'Import pandas' },
        fmta(
            [[
            import pandas as pd
        ]],
            {}
        )
    ),
    s(
        { trig = 'pdf', dscr = 'Pandas dataframe' },
        fmta(
            [[
            pd.DataFrame(<>, columns=[<>])
        ]],
            { i(1), i(2) }
        )
    ),
},
    {
        s({ trig = 'tq', dscr = 'Triple quotes' }, {
            t('"""'),
            f(visual_selection),
            i(1),
            t('"""'),
            i(0),
        }),
    }
