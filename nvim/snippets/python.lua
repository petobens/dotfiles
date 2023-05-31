local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local visual_selection = function(_, snip)
    return snip.env.TM_SELECTED_TEXT[1] or {}
end

return {
    -- Control flow
    s(
        { trig = 'class', dscr = 'Class' },
        fmta(
            [[
            class <>():
                """<>."""

                def __init__(self, <>):
                    <>
            ]],
            { i(1, 'Name'), i(2, 'docstring'), i(3, 'arg'), i(4, 'attr') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dec', dscr = 'Decorator' },
        fmta(
            [[
            def <>(<>):
                @wraps(func)
                def <>(<>):
                    <>

                return <>
            ]],
            {
                i(1, 'decorator_name'),
                i(2, 'func'),
                i(3, 'wrapper'),
                i(4, '*args, **kwargs'),
                i(5),
                rep(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'im', dscr = 'If main' },
        fmta(
            [[
               if __name__ == '__main__':
                    <>
            ]],
            { i(0) }
        ),
        { condition = line_begin }
    ),

    -- Logging, debugging and docstrings
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
        ),
        { condition = line_begin }
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
    s(
        { trig = 'npd', dscr = 'Numpy docstring' },
        fmta(
            [[
            """<>

            <>

            Parameters
            ----------
            <>
                <>

            Returns
            -------
            <>
                <>
            """
        ]],
            {
                i(1, 'one-line summary'),
                i(2, 'summary'),
                i(3, 'arg'),
                i(4, 'description'),
                i(5, 'type'),
                i(6, 'description'),
            }
        ),
        { condition = line_begin }
    ),

    -- Linting
    s(
        { trig = 'nl', dscr = 'No lint' },
        fmta(
            [[
            # type: ignore # noqa # pylint:disable=
        ]],
            {}
        )
    ),
    s(
        { trig = 'pld', dscr = 'Pylint disable' },
        fmta(
            [[
            # pylint:disable=
        ]],
            {}
        )
    ),
    s(
        { trig = 'mpi', dscr = 'Mypy ignore' },
        fmta(
            [[
            # type: ignore
        ]],
            {}
        )
    ),
    s(
        { trig = 'nq', dscr = 'Ruff noqa' },
        fmta(
            [[
            # noqa
        ]],
            {}
        )
    ),
    s(
        { trig = 'iss', dscr = 'isort skip' },
        fmta(
            [[
            # isort: skip
        ]],
            {}
        )
    ),

    -- Libraries
    s(
        { trig = 'ipd', dscr = 'Import pandas' },
        fmta(
            [[
            import pandas as pd
        ]],
            {}
        ),
        { condition = line_begin }
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
    s(
        { trig = 'inp', dscr = 'Import numpy' },
        fmta(
            [[
            import numpy as np
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ipp', dscr = 'Import pyplot as plt' },
        fmta(
            [[
            import matplotlib.pyplot as plt
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'imk', dscr = 'Import kitty backend' },
        fmta(
            [[
            import matplotlib

            matplotlib.use('module://matplotlib-backend-kitty')
        ]],
            {}
        ),
        { condition = line_begin }
    ),

    -- (Py)Tests
    s(
        { trig = 'ptf', dscr = 'Pytest fixture' },
        fmta(
            [[
            @pytest.fixture
            def <>(<>):
                <>
        ]],
            { i(1, 'f'), i(2), i(3) }
        ),
        { condition = line_begin }
    ),

    -- Miscellaneous
    s(
        { trig = 'pri', dscr = 'print' },
        fmta(
            [[
            print(<><>)
        ]],
            { f(visual_selection), i(1) }
        )
    ),
}, {
    s({ trig = 'tq', dscr = 'Triple quotes' }, {
        t('"""'),
        f(visual_selection),
        i(1),
        t('"""'),
        i(0),
    }),
    s({ trig = '--', wordTrig = false, dscr = 'Return' }, {
        t('->'),
        i(1),
    }),
}
