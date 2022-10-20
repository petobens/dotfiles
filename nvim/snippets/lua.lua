local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Luasnip
    s({ trig = 'snip', dscr = 'Snippet definition' }, {
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
        { trig = 'vis', dscr = 'Visual snippet' },
        fmta(
            [[
                f(function(_, snip)
                    return snip.env.TM_SELECTED_TEXT[<>] or {}
                end, {}),
            ]],
            {
                i(1, '1'),
            }
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

    -- Lua
    s(
        { trig = 'rq', dscr = 'Require' },
        fmta(
            [[
                require('<>')
            ]],
            {
                i(1, 'package'),
            }
        )
    ),
    s(
        { trig = 'lv', dscr = 'Local variable' },
        fmta(
            [[
                local <> = <>
            ]],
            {
                i(1, 'variable'),
                i(2, 'value'),
            }
        )
    ),
    s(
        { trig = 'if', dscr = 'If condition' },
        fmta(
            [[
                if <> then
                    <>
                end
            ]],
            {
                i(1, 'condition'),
                i(2, 'body'),
            }
        )
    ),
    s(
        { trig = 'ef', dscr = 'Empty function' },
        fmta(
            [[
                function()
                    <>
                end
            ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'lf', dscr = 'Local function definition' },
        fmta(
            [[
                local <> = function()
                    <>
                end
            ]],
            {
                i(1, 'fun_name'),
                i(2),
            }
        )
    ),
    s(
        { trig = 'fun', dscr = 'Function definition' },
        fmta(
            [[
                function <>()
                    <>
                end
            ]],
            {
                i(1, 'fun_name'),
                i(2),
            }
        )
    ),
},
    {}
