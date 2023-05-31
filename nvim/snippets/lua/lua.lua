local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local visual_selection = function(_, snip)
    return snip.env.TM_SELECTED_TEXT[1] or {}
end

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
        { trig = 'ef', dscr = 'Empty function' },
        fmta(
            [[
                function(<>)
                    <><>
                end
            ]],
            {
                i(1),
                f(visual_selection),
                i(2),
            }
        )
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
}, {}
