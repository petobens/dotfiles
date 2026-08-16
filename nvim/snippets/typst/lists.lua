local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
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
    list_snippet('enu', 'Numbered list', '+'),
    s(
        { trig = 'cenu', dscr = 'Custom-numbered list' },
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
        { trig = 'litm', dscr = 'Labeled items' },
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
    list_snippet('ste', 'Numbered steps', '+'),
    list_snippet('ite', 'Bullet list', '-'),
}, {
    -- List item
    s({ trig = 'itm', wordTrig = false, dscr = 'List item' }, {
        c(1, { t('- '), t('+ ') }),
        f(_G.LuaSnipConfig.visual_selection),
        i(0),
    }),
}
