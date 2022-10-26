local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Luasnip
    s({ trig = 'sni', dscr = 'Snippet definition' }, {
        t({ 's(', "\t{ trig = '" }),
        i(1, 'trigger'),
        t("', dscr = '"),
        i(2, 'description'),
        t({ "' },", '\tfmta(', '\t\t[[', '\t\t\t' }),
        i(3),
        t({ '', '\t\t]],', '\t\t{', '\t\t\t' }),
        i(4),
        t({ '', '\t\t}', '\t)', '),' }),
    }),
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
        )
    ),
    s(
        { trig = 'vis', dscr = 'Visual snippet' },
        fmta(
            [[
                f(visual_selection),
            ]],
            {}
        )
    ),
    s(
        { trig = 'cs', dscr = 'Choice snippet' },
        fmta(
            [[
                c(<>, { sn(nil, { i(<>, '<>')} ), t('') }),
            ]],
            { i(1, '1'), i(2, '1'), i(3, 'default_option') }
        )
    ),
    s(
        { trig = 'ns', dscr = 'Snippet node' },
        fmta(
            [[
                sn(nil, {
                    <>
                }),

            ]],
            {
                i(1, 'snippet body'),
            }
        )
    ),
},
    {}
