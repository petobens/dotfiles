local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

local function math_font(trigger, description, function_name)
    return s(
        { trig = trigger, dscr = description },
        fmta(function_name .. '(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    )
end

return {
    -- Text inside math
    s(
        { trig = 'tx', dscr = 'Text in math' },
        fmta('upright("<><>")<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'text'),
            i(0),
        })
    ),

    -- Math alphabets
    math_font('mcg', 'Calligraphic math', 'cal'),
    math_font('mbb', 'Blackboard bold math', 'bb'),
    math_font('mi', 'Italic math', 'italic'),
    math_font('mr', 'Upright math', 'upright'),
    math_font('mf', 'Fraktur math', 'frak'),
    math_font('msc', 'Script math', 'scr'),
}, {}
