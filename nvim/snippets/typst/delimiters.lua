local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

local function wrapped(trigger, description, opening, closing)
    return s(
        { trig = trigger, wordTrig = false, dscr = description },
        fmta(opening .. '<><>' .. closing .. '<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    )
end

return {
    -- Fixed and scalable math delimiters
    wrapped('bc', '[B]ra[c]es', '{ ', ' }'),
    wrapped('lr(', '[L]eft/[r]ight scalable parentheses', 'lr((', '))'),
    wrapped('lr[', '[L]eft/[r]ight scalable brackets', 'lr([', '])'),
    wrapped('lr{', '[L]eft/[r]ight scalable braces', 'lr({ ', ' })'),

    -- Spacing
    s(
        { trig = 'vs', dscr = '[V]ertical [s]pace' },
        fmta('#v(<>)<>', { i(1, '1em'), i(0) })
    ),
}, {}
