local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Control flow
    s(
        { trig = 'fun', dscr = 'Function definition' },
        fmta(
            [[
                function <>(<>)
                    <>
                end
            ]],
            {
                i(1, 'fun_name'),
                i(2),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'lf', dscr = 'Local function definition' },
        fmta(
            [[
                local function <>(<>)
                    <>
                end
            ]],
            {
                i(1, 'fun_name'),
                i(2),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ef', dscr = 'Empty function' },
        fmta(
            [[
                function(<>)
                    <><>
                end
            ]],
            {
                i(1),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        )
    ),
    s(
        { trig = 'for', dscr = 'For loop' },
        fmta(
            [[
                for <> do
                    <>
                end
            ]],
            {
                i(1, 'i = 1, n'),
                i(2),
            }
        ),
        { condition = line_begin }
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
        ),
        { condition = line_begin }
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
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pc', dscr = 'pcall' },
        fmta(
            [[
               local ok, <> = pcall(<>, '<>')
               if ok then
                   <>
                end
            ]],
            {
                i(1),
                i(2, 'func'),
                i(3, 'args'),
                i(4),
            }
        ),
        { condition = line_begin }
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
        ),
        { condition = line_begin }
    ),
    -- Libraries
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
    -- Linting
    s(
        { trig = 'li', dscr = 'Luacheck ignore' },
        fmta(
            [[
            -- luacheck:ignore <>
        ]],
            { i(1) }
        )
    ),
    -- Miscellaneous
    s(
        { trig = 'pri', dscr = 'print' },
        fmta(
            [[
            print(<><>)
        ]],
            { f(_G.LuaSnipConfig.visual_selection), i(1) }
        )
    ),
}, {
    s({ trig = 'db', dscr = 'Double brackets' }, {
        t('[['),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t(']]'),
        i(0),
    }),
}
