local ls = require('luasnip')

local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function display_equation(trigger, description)
    return s(
        { trig = trigger, dscr = description },
        fmta(
            [[
$
  <>
$

<>
            ]],
            { i(1, 'equation'), i(0) }
        ),
        { condition = line_begin }
    )
end

return {
    -- Equation blocks
    s(
        { trig = 'equ?', regTrig = true, docTrig = 'equ', dscr = 'Numbered [equ]ation' },
        fmta(
            [[
#equation($
  <>
$) <<eq:<>>>

<>
            ]],
            { i(1, 'equation'), i(2, 'label'), i(0) }
        ),
        { condition = line_begin }
    ),
    display_equation('ueq', '[U]nnumbered [eq]uation'),
    s(
        { trig = 'ali', dscr = 'Numbered [ali]gned equations' },
        fmta(
            [[
#equation($
  <> & = <> \
  <> & = <>
$) <<eq:<>>>

<>
            ]],
            {
                i(1, 'left-hand side'),
                i(2, 'right-hand side'),
                i(3, 'left-hand side'),
                i(4, 'right-hand side'),
                i(5, 'label'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ua', dscr = '[U]nnumbered [a]ligned equations' },
        fmta(
            [[
$
  <> & = <> \
  <> & = <>
$

<>
            ]],
            {
                i(1, 'left-hand side'),
                i(2, 'right-hand side'),
                i(3, 'left-hand side'),
                i(4, 'right-hand side'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Structures within math
    s(
        { trig = 'aed', dscr = '[A]lign[ed] rows' },
        fmta(
            [[<> & = <> \
<> & = <><>]],
            {
                i(1, 'left-hand side'),
                i(2, 'right-hand side'),
                i(3, 'left-hand side'),
                i(4, 'right-hand side'),
                i(0),
            }
        )
    ),
    s(
        { trig = 'sit', dscr = '[S]hort [i]n[t]ertext row' },
        fmta('#text[<>] \\<>', { i(1, 'Text'), i(0) })
    ),
    s(
        { trig = 'dca', dscr = '[D]isplay [ca]ses' },
        fmta(
            [[cases(
  <> & upright("<>") <>,
  <> & upright("<>") <>,
)<>]],
            {
                i(1, 'value'),
                i(2, 'if'),
                i(3, 'condition'),
                i(4, 'value'),
                i(5, 'otherwise'),
                i(6),
                i(0),
            }
        )
    ),
    s(
        { trig = 'mat', dscr = '[Mat]rix' },
        fmta(
            [[mat(
  <>, <>;
  <>, <>
)<>]],
            { i(1, 'a'), i(2, 'b'), i(3, 'c'), i(4, 'd'), i(0) }
        )
    ),
    s(
        { trig = 'max', dscr = '[Max]/min optimization problem' },
        fmta(
            [[
#equation($
  & <>_(<> in <>) quad && <> \
  & upright("<>") && <>
$) <<eq:<>>>

<>
            ]],
            {
                i(1, 'max'),
                i(2, 'x'),
                i(3, 'X'),
                i(4, 'f(x)'),
                i(5, 's.a'),
                i(6, 'g(x) lt.eq 0'),
                i(7, 'optimization_problem'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Economics
    s(
        { trig = 'fco', dscr = '[F]irst-order [co]nditions' },
        fmta(
            [[
#equation($
  (<>) & : quad & <> & = <> \
  (<>) & : quad & <> & = <>
$) <<eq:<>>>

<>
            ]],
            {
                i(1, 'x'),
                i(2, 'left-hand side'),
                i(3, 'right-hand side'),
                i(4, 'y'),
                i(5, 'left-hand side'),
                i(6, 'right-hand side'),
                i(7, 'first_order_conditions'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
}, {}
