local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Definitions
    s(
        { trig = 'nc', dscr = '[N]ew [c]ommand: define function or value' },
        fmta('#let <><> = <><>', {
            i(1, 'name'),
            c(2, {
                sn(nil, { t('('), i(1, 'arguments'), t(')') }),
                t(''),
            }),
            i(3, 'value'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'ne', dscr = '[N]ew [e]nvironment: define content function' },
        fmta(
            [[
#let <>(body) = [
  <>
  #body
  <>
]

<>
            ]],
            {
                i(1, 'name'),
                i(2, 'before'),
                i(3, 'after'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dmo', dscr = '[D]efine [m]ath [o]perator' },
        fmta('#let <> = math.op("<>")<>', {
            i(1, 'operator'),
            i(2, 'operator'),
            i(0),
        }),
        { condition = line_begin }
    ),

    -- Content-block function
    s(
        { trig = 'env', dscr = '[Env]ironment: content-block function' },
        fmta(
            [[
#<>[
  <><>
]

<>
            ]],
            {
                i(1, 'function'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'content'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Function call
    s(
        { trig = 'cmd', dscr = '[C]o[m]man[d]: function call' },
        fmta('#<>(<>)<>', { i(1, 'function'), i(2, 'arguments'), i(0) })
    ),
}, {}
