local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
local function table_cells(rows, columns, wrap_rows)
    local nodes = {}
    local index = 0

    for row = 1, rows do
        if wrap_rows then
            table.insert(nodes, t('('))
        end
        for column = 1, columns do
            index = index + 1
            table.insert(nodes, t('['))
            table.insert(nodes, i(index))
            if column < columns then
                table.insert(nodes, t('], '))
            elseif wrap_rows then
                table.insert(nodes, t(']'))
            else
                table.insert(nodes, t('],'))
            end
        end
        if wrap_rows then
            table.insert(nodes, t('),'))
        end
        if row < rows then
            table.insert(nodes, t({ '', '' }))
        end
    end

    return sn(nil, nodes)
end

return {
    -- Images and figures
    s(
        { trig = 'ig', dscr = '[I]nclude [g]raphics: image' },
        fmta('#image("<>", width: <>%)<>', {
            i(1),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'fig', dscr = '[Fig]ure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
<>  caption: [<>],
) <<fig:<>>><>]],
            {
                i(1),
                i(2, '100'),
                c(3, {
                    sn(nil, {
                        t('  placement: none,'),
                        i(1),
                        t({ '', '' }),
                    }),
                    t(''),
                }),
                i(4, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sflo', dscr = '[S]ub[flo]at: referenceable subfigures' },
        fmta(
            [[
#subfigure-grid(
  subfigure(
    image("<>", width: 100%, height: 100%, fit: "contain"),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  subfigure(
    image("<>", width: 100%, height: 100%, fit: "contain"),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  caption: [<>],
  label: <<fig:<>>>,
  panel-height: <>cm,
)<>]],
            {
                i(1),
                i(2, 'First panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(3),
                i(4, 'Second panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
                i(5, 'Combined caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 5 }),
                i(6, '5'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        {
            trig = 'fflo',
            dscr = '[F]igure [flo]ats: independently numbered side-by-side figures',
        },
        fmta(
            [[
#place(top, float: true)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    [#figure(
      image("<>", width: 100%),
      placement: auto,
      caption: [<>],
    ) <<fig:<>>>],
    [#figure(
      image("<>", width: 100%),
      placement: auto,
      caption: [<>],
    ) <<fig:<>>>],
  )
]<>]],
            {
                i(1),
                i(2, 'First caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(3),
                i(4, 'Second caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Tables
    s(
        { trig = 'tab', dscr = '[Tab]le from image' },
        fmta(
            [[
#figure(
  image("<>"),
  kind: table,
<>  caption: [<>],
) <<tab:<>>><>]],
            {
                i(1),
                c(2, {
                    sn(nil, {
                        t('  placement: none,'),
                        i(1),
                        t({ '', '' }),
                    }),
                    t(''),
                }),
                i(3, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 3 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'lt', dscr = '[L]aTeX [t]able helper' },
        fmta(
            [[
#latex-table(
  columns: <>,
  align: <>,
  header: ([<>], [<>], [<>]),
  rows: (
    ([<>], [<>], [<>]),
  ),
)<>]],
            {
                i(1, '(auto, auto, auto)'),
                i(2, '(left, right, right)'),
                i(3, 'Header 1'),
                i(4, 'Header 2'),
                i(5, 'Header 3'),
                i(6, 'Value 1'),
                i(7, 'Value 2'),
                i(8, 'Value 3'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rt', dscr = '[R]aw [t]able with custom rules' },
        fmta(
            [[
#table(
  columns: <>,
  align: <>,
  inset: <>,
  stroke: none,
  table.hline(stroke: <>),
  table.header(
    <>
  ),
  table.hline(stroke: <>),
  <>
  table.hline(stroke: <>),
)<>]],
            {
                i(1, '(auto, auto, auto)'),
                i(2, '(left, right, right)'),
                i(3, '(x: 6pt, y: 3.5pt)'),
                i(4, '0.8pt'),
                i(5, '[Header 1], [Header 2], [Header 3],'),
                i(6, '0.45pt'),
                i(7, '[Value 1], [Value 2], [Value 3],'),
                i(8, '0.8pt'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        {
            trig = '(%d+)c',
            regTrig = true,
            docTrig = '3c',
            dscr = '[3c] Flat table columns',
        },
        d(1, function(_, snip)
            return table_cells(1, tonumber(snip.captures[1]), false)
        end),
        { condition = line_begin }
    ),
    s(
        {
            trig = '(%d+)x(%d+)',
            regTrig = true,
            docTrig = '2x3',
            dscr = '[2x3] latex-table rows x columns',
        },
        d(1, function(_, snip)
            return table_cells(
                tonumber(snip.captures[1]),
                tonumber(snip.captures[2]),
                true
            )
        end),
        { condition = line_begin }
    ),
    s(
        {
            trig = 'r(%d+)x(%d+)',
            regTrig = true,
            docTrig = 'r2x3',
            dscr = '[r2x3] Raw table rows x columns',
        },
        d(1, function(_, snip)
            return table_cells(
                tonumber(snip.captures[1]),
                tonumber(snip.captures[2]),
                false
            )
        end),
        { condition = line_begin }
    ),
    s(
        { trig = 'hl', dscr = '[H]orizontal [l]ine' },
        c(1, {
            fmta('table.hline(stroke: <>),<>', { i(1, '0.8pt'), i(0) }),
            fmta('table.hline(start: <>, end: <>, stroke: <>),<>', {
                i(1, '1'),
                i(2, '3'),
                i(3, '0.45pt'),
                i(0),
            }),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'mul', wordTrig = false, dscr = '[Mul]ticolumn: spanning table cell' },
        fmta('table.cell(colspan: <>)[<><>],<>', {
            i(1, '2'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2),
            i(0),
        })
    ),
    s(
        {
            trig = 'mur',
            wordTrig = false,
            dscr = '[Mu]lti[r]ow: spanning table row',
        },
        fmta('table.cell(rowspan: <>)[<><>],<>', {
            i(1, '2'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2),
            i(0),
        })
    ),
}, {}
