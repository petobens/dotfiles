local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function wrapped(trigger, description, opening, closing)
    return s(
        { trig = trigger, dscr = description },
        fmta(opening .. '<><>' .. closing .. '<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    )
end

return {
    -- Emphasis
    wrapped('tb', '[T]ext [b]old/strong', '*', '*'),
    wrapped('ti', '[T]ext [i]talic', '_', '_'),
    s(
        { trig = 'cb', dscr = '[C]ode [b]lock' },
        fmta('```<>\n<><>\n```<>', {
            i(1, 'python'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2),
            i(0),
        }),
        { condition = line_begin }
    ),

    -- Notes and links
    s(
        { trig = 'fn', wordTrig = false, dscr = '[F]oot[n]ote' },
        fmta('#footnote[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    ),
    s(
        { trig = 'url', dscr = '[URL] link' },
        fmta('#link("<>")[<><>]<>', {
            i(1, 'https://example.com'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, 'Link text'),
            i(0),
        })
    ),

    -- Formatter directives
    s(
        { trig = 'tso', dscr = '[T]yp[s]tyle [o]ff: preserve next node formatting' },
        fmta('// @typstyle off\n<><>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'rpi', dscr = '[R]estore [p]aragraph [i]ndent after block' },
        fmta('#restore-paragraph-indent<>', { i(0) }),
        { condition = line_begin }
    ),

    -- Placeholder text
    s(
        { trig = 'li', wordTrig = false, dscr = '[L]orem [i]psum text' },
        fmta('#lorem(<>)<>', { i(1, '100'), i(0) })
    ),
}, {
    s({ trig = '``', wordTrig = false, dscr = 'Inline raw text' }, {
        t('`'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('`'),
        i(0),
    }),
}
