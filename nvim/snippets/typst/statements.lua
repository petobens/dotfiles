local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function numbered_statement(trigger, environment, prefix, description)
    return s(
        { trig = trigger, dscr = description },
        fmta('#' .. environment .. [[<>[
  <><>
] <<]] .. prefix .. [[:<>>>

<>
]], {
            c(1, {
                t(''),
                sn(nil, { t('(note: ['), i(1, 'Name'), t('])') }),
            }),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, description),
            i(3, 'label'),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function unnumbered_statement(trigger, environment, description)
    return s(
        { trig = trigger, dscr = 'Unnumbered ' .. description:lower() },
        fmta('#' .. environment .. [[(numbered: false<>)[
  <><>
]

<>
]], {
            c(1, {
                t(''),
                sn(nil, { t(', note: ['), i(1, 'Name'), t(']') }),
            }),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, description),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function solution_snippet(trigger)
    return s(
        { trig = trigger, dscr = 'Solution' },
        fmta(
            [[
#solution[
  <><>
]

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'Solution'),
                i(0),
            }
        ),
        { condition = line_begin }
    )
end

return {
    -- Theorems and theorem-like statements
    numbered_statement('thm', 'theorem', 'thm', 'Theorem'),
    unnumbered_statement('uthm', 'theorem', 'Theorem'),
    numbered_statement('pro', 'proposition', 'pro', 'Proposition'),
    unnumbered_statement('upro', 'proposition', 'Proposition'),
    numbered_statement('lem', 'lemma', 'lem', 'Lemma'),
    unnumbered_statement('ulem', 'lemma', 'Lemma'),
    numbered_statement('cor', 'corollary', 'cor', 'Corollary'),
    unnumbered_statement('ucor', 'corollary', 'Corollary'),
    numbered_statement('def', 'definition', 'def', 'Definition'),
    unnumbered_statement('udef', 'definition', 'Definition'),
    numbered_statement('exa', 'example', 'exa', 'Example'),
    unnumbered_statement('uexa', 'example', 'Example'),

    -- Examples and exercises
    s(
        { trig = 'exac', dscr = 'Continued example' },
        fmta(
            [[
#continued-example(<<exa:<>>>)[
  <><>
]

<>
            ]],
            {
                i(1, 'label'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    numbered_statement('exe', 'exercise', 'exe', 'Exercise'),
    unnumbered_statement('uexe', 'exercise', 'Exercise'),

    -- Remarks and solutions
    numbered_statement('rem', 'remark', 'rem', 'Remark'),
    unnumbered_statement('urem', 'remark', 'Remark'),
    unnumbered_statement('not', 'notation', 'Notation'),
    solution_snippet('sol'),
    solution_snippet('ans'),

    -- Proofs
    s(
        { trig = 'pr[fu]', regTrig = true, docTrig = 'pru', dscr = 'Proof' },
        fmta(
            [[
#proof[
  <><>
]

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
}, {}
