local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Control flow
    s(
        { trig = 'class', dscr = '[Class]' },
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
        { trig = 'def', dscr = '[Def]ine function' },
        fmta(
            [[
            def <>(<>):
                """<>."""
                <>
            ]],
            { i(1, 'func_name'), i(2, 'args'), i(3, 'docstring'), i(4) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dec', dscr = '[Dec]orator' },
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
        { trig = 'im', dscr = '[I]f [m]ain' },
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
        { trig = 'bl', dscr = '[B]asic [l]ogger' },
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
        { trig = 'li', dscr = '[L]ogger [i]nfo' },
        fmta(
            [[
            logger.<>(<><>)
        ]],
            {
                c(1, { t('info'), t('error'), t('warning') }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'bp', dscr = '[B]reak[p]oint' },
        fmta(
            [[
            breakpoint()
        ]],
            {}
        )
    ),
    s(
        { trig = 'npd', dscr = '[N]um[P]y [d]ocstring' },
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
    s(
        { trig = 'npp', dscr = '[N]um[P]y [p]arameters' },
        fmta(
            [[
            Parameters
            ----------
            <>
                <>

        ]],
            {
                i(1, 'arg'),
                i(2, 'description'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'npr', dscr = '[N]um[P]y [r]eturns' },
        fmta(
            [[
            Returns
            -------
            <>
                <>

        ]],
            {
                i(1, 'arg'),
                i(2, 'description'),
            }
        ),
        { condition = line_begin }
    ),

    -- Linting
    s(
        { trig = 'nl', dscr = '[N]o [l]int' },
        fmta(
            [[
            # type: ignore # noqa
        ]],
            {}
        )
    ),
    s(
        { trig = 'mpi', dscr = '[M]y[p]y [i]gnore' },
        fmta(
            [[
            # type: ignore
        ]],
            {}
        )
    ),
    s(
        { trig = 'nq', dscr = 'Ruff [n]o[q]a' },
        fmta(
            [[
            # noqa
        ]],
            {}
        )
    ),
    s(
        { trig = 'prd', dscr = '[P]y[r]ight [d]isable' },
        fmta(
            [[
            # pyright: ignore
        ]],
            {}
        )
    ),

    -- Libraries
    ---- Pandas
    s(
        { trig = 'ipd', dscr = '[I]mport [p]an[d]as' },
        fmta(
            [[
            import pandas as pd
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pmr', dscr = '[P]andas [m]ax [r]ows' },
        fmta(
            [[
            pd.set_option('display.max_rows', <>)
        ]],
            { i(1, '500') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pmc', dscr = '[P]andas [m]ax [c]olumns' },
        fmta(
            [[
            pd.set_option('display.width', <>)
        ]],
            { i(1, '1000') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pdf', dscr = '[P]andas [D]ata[F]rame' },
        fmta(
            [[
            pd.DataFrame(<>, columns=[<>])
        ]],
            { i(1), i(2) }
        )
    ),
    s(
        { trig = 'sdf', dscr = '[S]cratch [D]ata[F]rame' },
        fmta(
            [=[
            pd.DataFrame(
                [['a', 1, 'i'], ['b', 2, 'ii'], ['c', 3, 'iii']], columns=['l', 'n', 'r']
            )
        ]=],
            {}
        )
    ),
    s(
        { trig = 'rdf', dscr = '[R]andom [D]ata[F]rame' },
        fmta(
            [[
            pd.DataFrame(
                np.random.randint(0, 100, size=(<>, <>)), columns=[<>]
            )
        ]],
            {
                i(1, 'nrows'),
                i(2, 'ncols'),
                f(function(node_idx)
                    local nr_cols = tonumber(node_idx[1][1])
                    if not nr_cols then
                        nr_cols = 0
                    end
                    local col_names =
                        { "'A'", "'B'", "'C'", "'D'", "'E'", "'F'", "'G'", "'H'" }
                    return table.concat(col_names, ',', 1, nr_cols)
                end, { 2 }),
            }
        )
    ),
    ----- NumPy
    s(
        { trig = 'inp', dscr = '[I]mport [N]um[P]y' },
        fmta(
            [[
            import numpy as np
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    ----- Matplotlib
    s(
        { trig = 'ipp', dscr = '[I]mport [p]yplot as [p]lt' },
        fmta(
            [[
            import matplotlib.pyplot as plt
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'imk', dscr = '[I]mport [m]atplotlib [k]itcat backend' },
        fmta(
            [[
            import matplotlib

            matplotlib.use('kitcat')
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    ---- Datetime
    s(
        { trig = 'fdt', dscr = '[F]rom [d]a[t]etime' },
        fmta(
            [[
            from datetime import datetime
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    ---- (Py)Tests
    s(
        { trig = 'ptf', dscr = '[P]y[t]est [f]ixture' },
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
        { trig = 'pri', dscr = '[pri]nt' },
        fmta(
            [[
            print(<><>)
        ]],
            { f(_G.LuaSnipConfig.visual_selection), i(1) }
        )
    ),
    s(
        { trig = 'fs', dscr = '[f]-[s]tring' },
        fmta(
            [[
            f'<><>'
        ]],
            { f(_G.LuaSnipConfig.visual_selection), i(1) }
        )
    ),
    s(
        { trig = 'wo', dscr = '[W]ith [o]pen' },
        fmta(
            [[
            with open(<>, '<>') as <>:
                <>
        ]],
            { i(1, 'filepath'), i(2, 'r'), i(3, 'f'), i(4) }
        ),
        { condition = line_begin }
    ),
}, {
    s({ trig = 'tq', dscr = '[T]riple [q]uotes' }, {
        t('"""'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('"""'),
        i(0),
    }),
    s(
        { trig = 'fq', dscr = '[f]-string [q]uote' },
        fmta(
            [[
                f<><><><>
            ]],
            {
                c(1, { sn(nil, { i(1, '"') }), t("'") }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),
    s({ trig = '--', wordTrig = false, dscr = 'Return' }, {
        t('->'),
        i(1),
    }),
}
