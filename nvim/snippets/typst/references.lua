local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Labels and cross-references
    s(
        { trig = 'lab', wordTrig = false, dscr = 'Label' },
        fmta('<<<>>><>', { i(1, 'label'), i(0) })
    ),
    s({ trig = 'ref', dscr = 'Reference' }, fmta('@<><>', { i(1, 'label'), i(0) })),
    s(
        { trig = 'crg', dscr = 'General reference' },
        fmta('@<><>', { i(1, 'label'), i(0) })
    ),
    s({ trig = 'crc', dscr = 'Chapter reference' }, fmta('@cha:<><>', { i(1), i(0) })),
    s({ trig = 'crs', dscr = 'Section reference' }, fmta('@sec:<><>', { i(1), i(0) })),
    s({ trig = 'crf', dscr = 'Figure reference' }, fmta('@fig:<><>', { i(1), i(0) })),
    s(
        { trig = 'crsf', dscr = 'Subfigure reference' },
        fmta('@sfig:<><>', { i(1), i(0) })
    ),
    s({ trig = 'crt', dscr = 'Table reference' }, fmta('@tab:<><>', { i(1), i(0) })),
    s({ trig = 'cre', dscr = 'Equation reference' }, fmta('@eq:<><>', { i(1), i(0) })),
    s(
        { trig = 'crm', dscr = 'Statement reference' },
        fmta('@<>:<><>', {
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
    s({ trig = 'cri', dscr = 'List-item reference' }, fmta('@item:<><>', { i(1), i(0) })),

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
        { trig = 'ffc', wordTrig = false, dscr = 'Footnote with full citation' },
        fmta('#footnote[#cite(<<<>>>, form: "full")]<>', {
            i(1, 'citation-key'),
            i(0),
        })
    ),
    s(
        { trig = 'noc', dscr = 'Include source without citation' },
        fmta('#cite(<<<>>>, form: none)<>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'pb', dscr = 'Print bibliography' },
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
}, {}
