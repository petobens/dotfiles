local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function heading_snippet(trigger, level, prefix, description)
    return s(
        { trig = trigger, dscr = description },
        fmta(string.rep('=', level) .. [[ <>
<<]] .. prefix .. [[:<>>>

<>
]], {
            i(1, description .. ' name'),
            f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function unnumbered_heading_snippet(trigger, level, prefix, description)
    return s(
        { trig = trigger, dscr = 'Unnumbered ' .. description:lower() },
        fmta('#heading(level: ' .. level .. [[, numbering: none)[<>]
<<]] .. prefix .. [[:<>>>

<>
]], {
            i(1, description .. ' name'),
            f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function include_snippet(trigger)
    return s(
        { trig = trigger, dscr = 'Include file' },
        fmta('#include "<>"<>', { i(1, 'file.typ'), i(0) }),
        { condition = line_begin }
    )
end

local function appendix_snippet(trigger)
    return s(
        { trig = trigger, dscr = 'Appendix' },
        fmta(
            [[
// @typstyle off
#appendix[
<>
]

<>
            ]],
            { i(1), i(0) }
        ),
        { condition = line_begin }
    )
end

return {
    -- Includes
    include_snippet('ip'),
    include_snippet('ic'),

    -- Numbered headings
    heading_snippet('cha', 1, 'cha', 'Chapter'),
    heading_snippet('sec', 1, 'sec', 'Section'),
    heading_snippet('bsec', 2, 'sec', 'Book section'),
    heading_snippet('ss', 2, 'sub', 'Subsection'),
    heading_snippet('sss', 3, 'ssub', 'Subsubsection'),

    -- Unnumbered headings
    unnumbered_heading_snippet('usec', 1, 'sec', 'Article section'),
    unnumbered_heading_snippet('uss', 2, 'sub', 'Article subsection'),
    unnumbered_heading_snippet('usss', 3, 'ssub', 'Article subsubsection'),
    unnumbered_heading_snippet('ucha', 1, 'cha', 'Book chapter'),
    unnumbered_heading_snippet('ubsec', 2, 'sec', 'Book section'),
    unnumbered_heading_snippet('ubsub', 3, 'sub', 'Book subsection'),

    -- Appendices
    appendix_snippet('aa'),
    appendix_snippet('ba'),
}, {}
