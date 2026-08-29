local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function list_snippet(trigger, description, marker)
    return s(
        { trig = trigger, dscr = description },
        fmta(marker .. [[ <><>
]] .. marker .. [[ <>

<>
]], {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'First item'),
            i(2, 'Second item'),
            i(0),
        }),
        { condition = line_begin }
    )
end

return {
    -- List blocks
    list_snippet('enu', '[Enu]merate: numbered list', '+'),
    s(
        { trig = 'cenu', dscr = '[C]ustom [enu]merate: numbered list' },
        fmta(
            [[
#[
  #set enum(numbering: "<>", spacing: <>)
  + <><>

  + <>
]

<>
            ]],
            {
                i(1, '(i)'),
                i(2, '1em'),
                f(_G.LuaSnipConfig.visual_selection),
                i(3, 'First item'),
                i(4, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'citem', dscr = '[C]ustom [item]ize: bullet list' },
        fmta(
            [[
#[
  #set list(marker: <>, spacing: <>)
  - <><>

  - <>
]

<>
            ]],
            {
                i(1, '[–]'),
                i(2, '1em'),
                f(_G.LuaSnipConfig.visual_selection),
                i(3, 'First item'),
                i(4, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'litm', dscr = '[L]abeled [it]e[m]s' },
        fmta(
            [[
#labeled-item[<>][
  <><>
]

#labeled-item[<>][
  <>
]

<>
            ]],
            {
                i(1, 'First label'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'First item'),
                i(3, 'Second label'),
                i(4, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'wenu', dscr = '[W]ide [enu]merate: compact numbered list' },
        fmta(
            [[
#wide-enum(numbering: "<>")[
  + <><>
  + <>
]

<>
            ]],
            {
                i(1, '(i)'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'First item'),
                i(3, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    list_snippet('ite', '[Ite]mize: bullet list', '-'),
}, {
    -- List item
    s({ trig = 'itm', wordTrig = false, dscr = 'List [it]e[m]' }, {
        c(1, {
            sn(nil, { t('- '), i(1) }),
            sn(nil, { t('+ '), i(1) }),
        }),
        f(_G.LuaSnipConfig.visual_selection),
        i(0),
    }),
}
