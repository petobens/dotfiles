local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
local function numbered_statement(trigger, environment, prefix, label, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta('#' .. environment .. [[<>[
  <><>
] <<]] .. prefix .. [[:<>>><>]], {
            c(1, {
                sn(nil, { t('(note: ['), i(1, 'Name'), t('])') }),
                t(''),
            }),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, label),
            i(3, 'label'),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function unnumbered_statement(trigger, environment, label, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta('#' .. environment .. [[(numbered: false<>)[
  <><>
]<>]], {
            c(1, {
                sn(nil, { t(', note: ['), i(1, 'Name'), t(']') }),
                t(''),
            }),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, label),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function solution_snippet(trigger, dscr)
    return s(
        { trig = trigger, dscr = dscr },
        fmta(
            [[
#solution[
  <><>
]<>]],
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
    numbered_statement('thm', 'theorem', 'thm', 'Theorem', '[Th]eore[m]'),
    unnumbered_statement('uthm', 'theorem', 'Theorem', '[U]nnumbered [th]eore[m]'),
    numbered_statement('pro', 'proposition', 'pro', 'Proposition', '[Pro]position'),
    unnumbered_statement(
        'upro',
        'proposition',
        'Proposition',
        '[U]nnumbered [pro]position'
    ),
    numbered_statement('lem', 'lemma', 'lem', 'Lemma', '[Lem]ma'),
    unnumbered_statement('ulem', 'lemma', 'Lemma', '[U]nnumbered [lem]ma'),
    numbered_statement('cor', 'corollary', 'cor', 'Corollary', '[Cor]ollary'),
    unnumbered_statement('ucor', 'corollary', 'Corollary', '[U]nnumbered [cor]ollary'),
    numbered_statement('def', 'definition', 'def', 'Definition', '[Def]inition'),
    unnumbered_statement('udef', 'definition', 'Definition', '[U]nnumbered [def]inition'),
    numbered_statement('exa', 'example', 'exa', 'Example', '[Exa]mple'),
    unnumbered_statement('uexa', 'example', 'Example', '[U]nnumbered [exa]mple'),

    -- Examples and exercises
    s(
        { trig = 'exac', dscr = '[Exa]mple [c]ontinued' },
        fmta(
            [[
#continued-example(<<exa:<>>>)[
  <><>
]<>]],
            {
                i(1, 'label'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    numbered_statement('exe', 'exercise', 'exe', 'Exercise', '[Exe]rcise'),
    unnumbered_statement('uexe', 'exercise', 'Exercise', '[U]nnumbered [exe]rcise'),

    -- Remarks and solutions
    numbered_statement('rem', 'remark', 'rem', 'Remark', '[Rem]ark'),
    unnumbered_statement('urem', 'remark', 'Remark', '[U]nnumbered [rem]ark'),
    unnumbered_statement('not', 'notation', 'Notation', '[Not]ation (unnumbered)'),
    solution_snippet('sol', '[Sol]ution'),

    -- Proofs
    s(
        {
            trig = 'pr[fu]',
            regTrig = true,
            docTrig = 'pru',
            dscr = '[Pr]oo[f]/[Pru]eba',
        },
        fmta(
            [[
#proof[
  <><>
]<>]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
}, {}
