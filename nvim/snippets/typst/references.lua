local ls = require('luasnip')

local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Labels and cross-references
    s(
        { trig = 'lab', wordTrig = false, dscr = '[Lab]el' },
        fmta('<<<>>><>', { i(1, 'label'), i(0) })
    ),
    s({ trig = 'ref', dscr = '[Ref]erence' }, fmta('@<><>', { i(1, 'label'), i(0) })),
    s(
        { trig = 'crc', dscr = '[C]leve[r]ef [c]hapter reference' },
        fmta('@cha:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crs', dscr = '[C]leve[r]ef [s]ection reference' },
        fmta('@sec:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crf', dscr = '[C]leve[r]ef [f]igure reference' },
        fmta('@fig:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crsf', dscr = '[C]leve[r]ef [s]ub[f]igure reference' },
        fmta('@sfig:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crt', dscr = '[C]leve[r]ef [t]able reference' },
        fmta('@tab:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'cre', dscr = '[C]leve[r]ef [e]quation reference' },
        fmta('@eq:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crd', dscr = '[C]leve[r]ef [d]efinition reference' },
        fmta('@def:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crp', dscr = '[C]leve[r]ef [p]roposition reference' },
        fmta('@pro:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crth', dscr = '[C]leve[r]ef [th]eorem reference' },
        fmta('@thm:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crl', dscr = '[C]leve[r]ef [l]emma reference' },
        fmta('@lem:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crco', dscr = '[C]leve[r]ef [co]rollary reference' },
        fmta('@cor:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crem', dscr = '[C]leve[r]ef [e]xa[m]ple reference' },
        fmta('@exa:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crex', dscr = '[C]leve[r]ef [ex]ercise reference' },
        fmta('@exe:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'crr', dscr = '[C]leve[r]ef [r]emark reference' },
        fmta('@rem:<><>', { i(1), i(0) })
    ),
    s(
        { trig = 'cri', dscr = '[C]leve[r]ef [i]tem reference' },
        fmta('@item:<><>', { i(1), i(0) })
    ),

    -- Citations and bibliography
    s(
        { trig = 'tc', dscr = '[T]ext[c]ite: prose citation' },
        fmta('#cite(<<<>>>, form: "prose")<>', { i(1), i(0) })
    ),
    s(
        { trig = 'fc', dscr = '[F]ull [c]itation' },
        fmta('#cite(<<<>>>, form: "full")<>', { i(1), i(0) })
    ),
    s(
        { trig = 'ffc', wordTrig = false, dscr = '[F]ootnote with [f]ull [c]itation' },
        fmta('#footnote[#cite(<<<>>>, form: "full")]<>', {
            i(1),
            i(0),
        })
    ),
    s(
        { trig = 'noc', dscr = '[Noc]ite: include source without citation' },
        fmta('#cite(<<<>>>, form: none)<>', { i(1), i(0) })
    ),
    s(
        { trig = 'pb', dscr = '[P]rint [b]ibliography' },
        fmta(
            [[
#bibliography(
  read("<>", encoding: none),
  title: localized([Referencias], [References]),
)

<>
            ]],
            {
                i(1, 'references.yml'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cbib', dscr = '[C]hapter [bib]liographies' },
        fmta('#chapter-bibliographies(read("<>", encoding: none))<>', {
            i(1, 'references.yml'),
            i(0),
        }),
        { condition = line_begin }
    ),

    -- Indexes
    s(
        { trig = 'idx', wordTrig = false, dscr = '[I]n[d]e[x] entry' },
        fmta('#index("<>")<>', { i(1, 'entry'), i(0) })
    ),
}, {}
