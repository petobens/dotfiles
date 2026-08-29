local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
local function heading_snippet(trigger, level, prefix, label, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta(string.rep('=', level) .. [[ <>
<<]] .. prefix .. [[:<>>>

<>
]], {
            i(1, label .. ' name'),
            f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function unnumbered_heading_snippet(trigger, level, prefix, label, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta('#heading(level: ' .. level .. [[, numbering: none)[<>]
<<]] .. prefix .. [[:<>>>

<>
]], {
            i(1, label .. ' name'),
            f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function include_snippet(trigger, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta('#include "<>"<>', { i(1, 'file.typ'), i(0) }),
        { condition = line_begin }
    )
end

local function appendix_snippet(trigger, dscr)
    return s(
        { trig = trigger, dscr = dscr },
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
    include_snippet('ic', '[I]n[c]lude file'),

    -- Numbered headings
    heading_snippet('cha', 1, 'cha', 'Chapter', '[Cha]pter'),
    heading_snippet('sec', 1, 'sec', 'Section', '[Sec]tion'),
    heading_snippet('bsec', 2, 'sec', 'Book section', '[B]ook [sec]tion'),
    heading_snippet('ss', 2, 'sub', 'Subsection', '[S]ub[s]ection'),
    heading_snippet('sss', 3, 'ssub', 'Subsubsection', '[S]ub[s]ub[s]ection'),

    -- Unnumbered headings
    unnumbered_heading_snippet(
        'usec',
        1,
        'sec',
        'Article section',
        '[U]nnumbered [sec]tion (article)'
    ),
    unnumbered_heading_snippet(
        'uss',
        2,
        'sub',
        'Article subsection',
        '[U]nnumbered [s]ub[s]ection'
    ),
    unnumbered_heading_snippet(
        'usss',
        3,
        'ssub',
        'Article subsubsection',
        '[U]nnumbered [s]ub[s]ub[s]ection'
    ),
    unnumbered_heading_snippet(
        'ucha',
        1,
        'cha',
        'Book chapter',
        '[U]nnumbered [cha]pter (book)'
    ),
    unnumbered_heading_snippet(
        'ubsec',
        2,
        'sec',
        'Book section',
        '[U]nnumbered [b]ook [sec]tion'
    ),
    unnumbered_heading_snippet(
        'ubsub',
        3,
        'sub',
        'Book subsection',
        '[U]nnumbered [b]ook [sub]section'
    ),

    -- Appendices
    appendix_snippet('app', '[App]endix'),
}, {}
