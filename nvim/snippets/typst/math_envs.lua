local ls = require('luasnip')

local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
local function equation_body(_, parent)
    local lines = parent.snippet.env.LS_SELECT_DEDENT or {}
    if
        #lines >= 4
        and lines[1]:match('^%s*#equation%(%s*$')
        and lines[2]:match('^%s*%$%s*$')
        and lines[#lines - 1]:match('^%s*%$,%s*$')
        and lines[#lines]:match('^%s*%)%s*<eq:[^>]+>%s*$')
    then
        lines = vim.list_slice(lines, 3, #lines - 2)
    elseif
        #lines >= 2
        and lines[1]:match('^%s*#equation%(%$%s*$')
        and lines[#lines]:match('^%s*%$%)%s*<eq:[^>]+>%s*$')
    then
        lines = vim.list_slice(lines, 2, #lines - 1)
    elseif
        #lines >= 2
        and lines[1]:match('^%s*%$%s*$')
        and lines[#lines]:match('^%s*%$%s*$')
    then
        lines = vim.list_slice(lines, 2, #lines - 1)
    end

    local indent
    for _, line in ipairs(lines) do
        local whitespace = line:match('^(%s*)%S')
        if whitespace then
            indent = math.min(indent or #whitespace, #whitespace)
        end
    end
    if indent and indent > 0 then
        for index, line in ipairs(lines) do
            lines[index] = line:sub(indent + 1)
        end
    end
    for index = 2, #lines do
        lines[index] = lines[index] == '' and '' or '  ' .. lines[index]
    end
    return sn(nil, { i(1, #lines > 0 and lines or 'equation') })
end

local function display_equation(trigger, description)
    return s(
        { trig = trigger, dscr = description },
        fmta(
            [[
$
  <>
$<>]],
            { d(1, equation_body), i(0) }
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
$) <<eq:<>>><>]],
            { d(1, equation_body), i(2, 'label'), i(0) }
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
$) <<eq:<>>><>]],
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
$<>]],
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
$) <<eq:<>>><>]],
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
$) <<eq:<>>><>]],
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
