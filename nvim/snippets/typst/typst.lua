local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
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

local function numbered_statement(trigger, environment, prefix, description)
    return s(
        { trig = trigger, dscr = description },
        fmta('#' .. environment .. [[[
  <><>
] <<]] .. prefix .. [[:<>>>

<>
]], {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, description),
            i(2, 'label'),
            i(0),
        }),
        { condition = line_begin }
    )
end

local function unnumbered_statement(trigger, environment, description)
    return s(
        { trig = trigger, dscr = 'Unnumbered ' .. description:lower() },
        fmta('#' .. environment .. [[(
  numbered: false,
)[
  <><>
]

<>
]], {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, description),
            i(0),
        }),
        { condition = line_begin }
    )
end

return {
    -- Document structure
    heading_snippet('cha', 1, 'cha', 'Chapter'),
    heading_snippet('sec', 1, 'sec', 'Section'),
    heading_snippet('bsec', 2, 'sec', 'Book section'),
    heading_snippet('ss', 2, 'sub', 'Subsection'),
    heading_snippet('sss', 3, 'ssub', 'Subsubsection'),
    unnumbered_heading_snippet('usec', 1, 'sec', 'Article section'),
    unnumbered_heading_snippet('uss', 2, 'sub', 'Article subsection'),
    unnumbered_heading_snippet('usss', 3, 'ssub', 'Article subsubsection'),
    unnumbered_heading_snippet('ucha', 1, 'cha', 'Book chapter'),
    unnumbered_heading_snippet('ubsec', 2, 'sec', 'Book section'),
    unnumbered_heading_snippet('ubsub', 3, 'sub', 'Book subsection'),
    s(
        { trig = 'aa', dscr = 'Article appendix' },
        fmta(
            [[
#appendix[
  <>
]

<>
            ]],
            { i(1), i(0) }
        ),
        { condition = line_begin }
    ),

    -- Text and lists
    s(
        { trig = 'tb', dscr = 'Strong text' },
        fmta('*<><>*<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    ),
    s(
        { trig = 'ti', dscr = 'Emphasized text' },
        fmta('_<><>_<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1),
            i(0),
        })
    ),
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
    s(
        { trig = 'enu', dscr = 'Numbered list' },
        fmta(
            [[
+ <><>
+ <>

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'First item'),
                i(2, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ite', dscr = 'Bullet list' },
        fmta(
            [[
- <><>
- <>

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'First item'),
                i(2, 'Second item'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'lorem', dscr = 'Lorem ipsum text' },
        fmta('#lorem(<>)<>', { i(1, '100'), i(0) }),
        { condition = line_begin }
    ),

    -- Equations
    s(
        { trig = 'equ?', regTrig = true, docTrig = 'equ', dscr = 'Numbered equation' },
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
    s(
        { trig = 'ueq', dscr = 'Unnumbered equation' },
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
    ),

    -- Figures and tables
    s(
        { trig = 'ig', dscr = 'Image' },
        fmta('#image("<>", width: <>%)<>', {
            i(1, 'image.svg'),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'fig', dscr = 'Figure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
  caption: [<>],
) <<fig:<>>>

<>
            ]],
            {
                i(1, 'image.svg'),
                i(2, '100'),
                i(3, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 3 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'subf', dscr = 'Referenceable subfigures' },
        fmta(
            [[
#subfigure-grid(
  subfigure(
    image("<>", width: 100%),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  subfigure(
    image("<>", width: 100%),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  caption: [<>],
  label: <<fig:<>>>,
)

<>
            ]],
            {
                i(1, 'image-a.svg'),
                i(2, 'First panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(3, 'image-b.svg'),
                i(4, 'Second panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
                i(5, 'Combined caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 5 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tab', dscr = 'Table from image' },
        fmta(
            [[
#figure(
  image("<>"),
  kind: table,
  caption: [<>],
) <<tab:<>>>

<>
            ]],
            {
                i(1, 'table.pdf'),
                i(2, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rt', dscr = 'Native table' },
        fmta(
            [[
#latex-table(
  columns: <>,
  align: <>,
  header: ([<>], [<>], [<>]),
  rows: (
    ([<>], [<>], [<>]),
  ),
)

<>
            ]],
            {
                i(1, '(2fr, 1fr, 1fr)'),
                i(2, '(left, right, right)'),
                i(3, 'Indicator'),
                i(4, '2020'),
                i(5, '2025'),
                i(6, 'Productivity'),
                i(7, '100'),
                i(8, '114'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Statements and proofs
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
    numbered_statement('exe', 'exercise', 'exe', 'Exercise'),
    unnumbered_statement('uexe', 'exercise', 'Exercise'),
    numbered_statement('rem', 'remark', 'rem', 'Remark'),
    unnumbered_statement('urem', 'remark', 'Remark'),
    unnumbered_statement('not', 'notation', 'Notation'),
    s(
        { trig = 'sol', dscr = 'Solution' },
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
    ),
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

    -- References
    s(
        { trig = 'lab', wordTrig = false, dscr = 'Label' },
        fmta('<<<>>><>', { i(1, 'label'), i(0) })
    ),
    s({ trig = 'ref', dscr = 'Reference' }, fmta('@<><>', { i(1, 'label'), i(0) })),
    s(
        { trig = 'crs', dscr = 'Section reference' },
        fmta('@<<sec:<>>><>', { i(1), i(0) })
    ),
    s({ trig = 'crf', dscr = 'Figure reference' }, fmta('@<<fig:<>>><>', { i(1), i(0) })),
    s(
        { trig = 'crsf', dscr = 'Subfigure reference' },
        fmta('@<<sfig:<>>><>', { i(1), i(0) })
    ),
    s({ trig = 'crtb', dscr = 'Table reference' }, fmta('@<<tab:<>>><>', { i(1), i(0) })),
    s(
        { trig = 'cre', dscr = 'Equation reference' },
        fmta('@<<eq:<>>><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crt', dscr = 'Statement reference' },
        fmta('@<<<>:<>>><>', {
            c(1, {
                t('thm'),
                t('pro'),
                t('lem'),
                t('cor'),
                t('def'),
                t('exa'),
                t('exe'),
                t('rem'),
            }),
            i(2),
            i(0),
        })
    ),

    -- Citations and bibliography
    s(
        { trig = 'cite', dscr = 'Citation' },
        fmta('@<><>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'tc', dscr = 'Prose citation' },
        fmta('#cite(<<<>>>, form: "prose")<>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'fc', dscr = 'Full citation' },
        fmta('#cite(<<<>>>, form: "full")<>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'noc', dscr = 'Include source without citation' },
        fmta('#cite(<<<>>>, form: none)<>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'bib', dscr = 'Bibliography' },
        fmta(
            [[
#bibliography(
  read("<>", encoding: none),
  title: localized([Referencias], [References]),
)

<>
            ]],
            {
                i(1, 'references.bib'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Typst functions
    s(
        { trig = 'fun', dscr = 'Content block function' },
        fmta(
            [[
#<>[
  <>
]<>
            ]],
            { i(1, 'function'), i(2, 'content'), i(0) }
        )
    ),
    s(
        { trig = 'call', dscr = 'Function call' },
        fmta('#<>(<>)<>', { i(1, 'function'), i(2, 'arguments'), i(0) })
    ),
}, {
    s({ trig = 'itm', wordTrig = false, dscr = 'List item' }, {
        c(1, { t('- '), t('+ ') }),
        f(_G.LuaSnipConfig.visual_selection),
        i(0),
    }),
}
