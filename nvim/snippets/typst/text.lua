local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

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
    wrapped('tb', 'Strong text', '*', '*'),
    wrapped('ti', 'Italic text', '_', '_'),
    wrapped('emph', 'Emphasized text', '#emph[', ']'),
    wrapped('tss', 'Sans-serif text', '#text(font: "DejaVu Sans")[', ']'),
    wrapped('muc', 'Uppercase text', '#upper[', ']'),
    wrapped('quo', 'Inline quotation', '#quote(block: false)[', ']'),
    s(
        { trig = 'ttt', dscr = 'Monospaced text' },
        fmta('#raw("<><>")<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    ),

    -- Notes and links
    s(
        { trig = 'fn', wordTrig = false, dscr = 'Footnote' },
        fmta('#footnote[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    ),
    s(
        { trig = 'url', dscr = 'Link' },
        fmta('#link("<>")[<><>]<>', {
            i(1, 'https://example.com'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, 'Link text'),
            i(0),
        })
    ),

    -- Placeholder text
    s(
        { trig = 'lorem', wordTrig = false, dscr = 'Lorem ipsum text' },
        fmta('#lorem(<>)<>', { i(1, '100'), i(0) }),
        { condition = line_begin }
    ),
}, {}
