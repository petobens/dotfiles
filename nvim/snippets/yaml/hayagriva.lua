local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local l = extras.lambda
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Helpers
local function bibkey(args)
    local author = table.concat(args[1], '\n'):match('^%s*%-?%s*(%S[^\n]*)')
    if not author then
        return ''
    end

    local surname = author:match('^([^,]+),') or author:match('(%S+)%s*$')
    return surname:lower():gsub('%s+', '')
end

local function parent_type(args)
    local parents = {
        Anthos = 'Anthology',
        Article = 'Proceedings',
        Chapter = 'Book',
    }
    return sn(nil, t(parents[args[1][1]]))
end

return {
    s(
        { trig = 'art', dscr = '[Art]icle' },
        fmta(
            [[
            <><>:
                type: Article
                title: <>
                author: <>
                date: <>
                page-range: <><>
                parent:
                    type: Periodical
                    title: <>
                    volume: <>
                    issue: <>
            ]],
            {
                f(bibkey, { 2 }),
                l(l._1:sub(-2), 3),
                i(1),
                i(2),
                i(3),
                i(4),
                c(5, {
                    sn(nil, {
                        t({ '', '    serial-number:', '        doi: ' }),
                        i(1),
                    }),
                    t(''),
                }),
                i(6),
                i(7),
                i(8),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'book', dscr = '[Book]' },
        fmta(
            [[
            <><>:
                type: Book
                title: <>
                author: <>
                publisher:
                    name: <>
                    location: <><>
                date: <>
            ]],
            {
                f(bibkey, { 2 }),
                l(l._1:sub(-2), 6),
                i(1),
                i(2),
                i(3),
                i(4),
                c(5, { sn(nil, { t({ '', '    edition: ' }), i(1) }), t('') }),
                i(6),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'in', dscr = '[In] Book|Proceedings|Collection' },
        fmta(
            [[
            <><>:
                type: <>
                title: <>
                author: <>
                page-range: <>
                date: <>
                parent:
                    type: <>
                    title: <>
                    editor: <>
                    publisher: <>
            ]],
            {
                f(bibkey, { 3 }),
                l(l._1:sub(-2), 5),
                c(1, { t('Chapter'), t('Article'), t('Anthos') }),
                i(2),
                i(3),
                i(4),
                i(5),
                d(6, parent_type, { 1 }),
                i(7),
                i(8),
                i(9),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tr', dscr = '[T]echnical [r]eport' },
        fmta(
            [[
            <><>:
                type: Report
                title: <>
                author: <>
                genre: <>
                serial-number: <>
                organization: <>
                date: <>
            ]],
            {
                f(bibkey, { 2 }),
                l(l._1:sub(-2), 6),
                i(1),
                i(2),
                i(3, 'Working Paper'),
                i(4),
                i(5),
                i(6),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'phd', dscr = '[PhD] thesis' },
        fmta(
            [[
            <><>:
                type: Thesis
                title: <>
                author: <>
                genre: Doctoral dissertation
                organization: <>
                location: <>
                date: <>
            ]],
            {
                f(bibkey, { 2 }),
                l(l._1:sub(-2), 5),
                i(1),
                i(2),
                i(3),
                i(4),
                i(5),
            }
        ),
        { condition = line_begin }
    ),
}, {}
