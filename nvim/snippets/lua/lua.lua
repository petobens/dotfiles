local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta

return {
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
    s(
        { trig = 'fp', dscr = 'For pair' },
        fmta(
            [[
                for k, v in pairs(<>) do
                    <>
                end
            ]],
            {
                i(1),
                i(2),
            }
        )
    ),
},
    {}
