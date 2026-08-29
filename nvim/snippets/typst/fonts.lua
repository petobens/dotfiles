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
        { trig = 'btx', dscr = '[B]oxed [t]e[x]t in math (unbreakable)' },
        fmta('#box[$"<><>"$]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'text'),
            i(0),
        })
    ),

    -- Math alphabets
    math_font('mcg', '[M]ath [c]alli[g]raphic', 'cal'),
    math_font('mbb', '[M]ath [b]lackboard [b]old', 'bb'),
    math_font('mr', '[M]ath [r]oman/upright', 'upright'),
    math_font('mf', '[M]ath [f]raktur', 'frak'),
    math_font('msc', '[M]ath [sc]ript', 'scr'),
}, {}
