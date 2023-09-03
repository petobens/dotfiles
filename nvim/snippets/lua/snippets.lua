local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Luasnip
    s({ trig = 'sni', dscr = 'Snippet snippet' }, {
        t({ 's(', "\t{ trig = '" }),
        i(1, 'trigger'),
        t("', "),
        c(2, { sn(nil, { i(1, 'wordTrig = false, ') }), t('') }),
        t("dscr = '"),
        i(3, 'description'),
        t({ "' },", '\tfmta(', '\t\t[[', '\t\t\t' }),
        i(4),
        t({ '', '\t\t]],', '\t\t{', '\t\t\t' }),
        i(5),
        t({ '', '\t\t}', '\t)' }),
        c(
            6,
            { sn(nil, { t({ ',', '' }), i(1, '\t{ condition = line_begin }') }), t('') }
        ),
        t({ '', '),' }),
    }),
    s(
        { trig = 'in', dscr = 'Insert node' },
        fmta(
            [[
                i(<><>),
            ]],
            {
                i(1, '1'),
                c(2, { sn(nil, { t(", '"), i(1), t("'") }), t('') }),
            }
        )
    ),
    s(
        { trig = 'tn', dscr = 'Text node' },
        fmta(
            [[
                t('<>'),
            ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'sn', dscr = 'Snippet node' },
        fmta(
            [[
                sn(nil, { <> }),
            ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'cn', dscr = 'Choice node' },
        fmta(
            [[
                c(<>, { <>, <> }),
            ]],
            {
                i(1, '1'),
                c(2, {
                    sn(nil, { i(1) }),
                    sn(nil, { t('sn(nil, { '), i(1, ''), t(' })') }),
                }),
                i(3),
            }
        )
    ),
    s(
        { trig = 'fn', dscr = 'Function node' },
        fmta(
            [[
                f(function(node_idx)
                    local <> = node_idx[1][1]
                    <>
                end, { <> }),
            ]],
            { i(1, 'var'), i(2), i(3, '1') }
        )
    ),
    s(
        { trig = 'dn', dscr = 'Dynamic node' },
        fmta(
            [[
                d(<>, function(args, snip)
                    local nodes = {}
                    <>
                    return sn(nil, nodes)
                end),
            ]],
            { i(1, '1'), i(2) }
        )
    ),
    s(
        { trig = 'mn', dscr = 'Match node' },
        fmta(
            [[
                m(1, '^<>$', <>, <>),
            ]],
            {
                i(1, 'condition'),
                i(2, 'true'),
                i(3, 'false'),
            }
        )
    ),
    s(
        { trig = 'ln', dscr = 'Lambda node' },
        fmta(
            [[
                l(l._1:<>, <>),
            ]],
            {
                i(1, 'func'),
                i(2, '1'),
            }
        )
    ),
    s(
        { trig = 'pn', dscr = 'Partial node' },
        fmta(
            [[
                p(<><>),
            ]],
            {
                i(1, 'func'),
                c(2, { sn(nil, { t(", '"), i(1, 'args'), t("'") }), t('') }),
            }
        )
    ),
    s(
        { trig = 'rn', dscr = 'Rep node' },
        fmta(
            [[
                rep(<>),
            ]],
            {
                i(1, '1'),
            }
        )
    ),
    s(
        { trig = 'wt', dscr = 'Word trigger' },
        fmta(
            [[
                wordTrig = false,
            ]],
            {}
        )
    ),
    s(
        { trig = 'rt', dscr = 'Regex trigger' },
        fmta(
            [[
                regTrig = true,
            ]],
            {}
        )
    ),
    s(
        { trig = 'lbc', dscr = 'Line begin condition' },
        fmta(
            [[
               { condition = line_begin }
            ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'vs', dscr = 'Visual selection' },
        fmta(
            [[
                f(_G.LuaSnipConfig.visual_selection),
            ]],
            {}
        )
    ),
    s(
        { trig = 'vi', dscr = 'Visual indent' },
        fmta(
            [[
                isn(<>, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
            ]],
            { i(1) }
        )
    ),
}, {}
