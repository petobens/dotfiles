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

local function bibkey(node_idx)
    local authors = node_idx[1][1]
    if not authors or authors == '' then
        return ''
    end

    local first_author = vim.fn.split(authors:lower(), 'and')[1]
    local first_author_surname
    if string.find(first_author, ',') then
        first_author_surname = vim.fn.split(first_author, ',')[1]
    else
        first_author_surname = vim.fn.split(first_author, ' ')
        first_author_surname = first_author_surname[#first_author_surname]
    end
    first_author_surname = first_author_surname:gsub('%s+', '')
    return first_author_surname
end

return {
    s(
        { trig = 'art', dscr = 'Article' },
        fmta(
            [[
            @Article{<><>,
              author  = {<>},
              title   = {<>},
              journal = {<>},
              year    = {<>},
              volume  = {<>},
              number  = {<>},
              pages   = {<>},
            }
            ]],
            {
                f(bibkey, { 1 }),
                l(l._1:sub(-2), 4),
                i(1),
                i(2),
                i(3),
                i(4),
                i(5),
                i(6),
                i(7),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'book', dscr = 'Book' },
        fmta(
            [[
            @Book{<><>,
              author    =  {<>},
              title     =  {<>},
              publisher =  {<>},<>
              address   =  {<>},
              year      =  {<>},
            }
            ]],
            {
                f(bibkey, { 1 }),
                l(l._1:sub(-2), 6),
                i(1),
                i(2),
                i(3),
                c(
                    4,
                    { sn(nil, { t({ '', '  edition   =  {' }), i(1), t('},') }), t('') }
                ),
                i(5),
                i(6),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'in', dscr = 'InBook|Proceedings|Collection' },
        fmta(
            [[
            @In<>{<><>,
              author       = {<>},
              title        = {<>},<>
              publisher    = {<>},
              address      = {<>},
              year         = {<>},
            }
            ]],
            {
                c(1, { t('Book'), t('Proceedings'), t('Collection') }),
                f(bibkey, { 2 }),
                l(l._1:sub(-2), 7),
                i(2),
                i(3),
                d(4, function(args)
                    local nodes
                    local entry_type = args[1][1]
                    if entry_type == 'Book' then
                        nodes = {
                            t({ '', '  chapter      = {' }),
                            i(1),
                            t('},'),
                            c(2, {
                                sn(
                                    nil,
                                    { t({ '', '  pages        = {' }), i(1), t('},') }
                                ),
                                t(''),
                            }),
                        }
                    else
                        nodes = {
                            t({ '', '  booktitle    = {' }),
                            i(1),
                            t('},'),
                            c(2, {
                                sn(
                                    nil,
                                    { t({ '', '  editor       = {' }), i(1), t('},') }
                                ),
                                t(''),
                            }),
                            c(3, {
                                sn(
                                    nil,
                                    { t({ '', '  volume       = {' }), i(1), t('},') }
                                ),
                                t(''),
                            }),
                        }
                    end
                    return sn(nil, nodes)
                end, { 1 }),
                i(5),
                i(6),
                i(7),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tr', dscr = 'Technical Report' },
        fmta(
            [[
            @TechReport{<><>,
              author       = {<>},
              title        = {<>},
              type         = {<>},<><><>
              year         = {<>},
            }
            ]],
            {
                f(bibkey, { 1 }),
                l(l._1:sub(-2), 7),
                i(1),
                i(2),
                i(3, 'Working Paper'),
                c(
                    4,
                    { sn(nil, { t({ '', '  number       = {' }), i(1), t('},') }), t('') }
                ),
                c(
                    5,
                    { sn(nil, { t({ '', '  institution  = {' }), i(1), t('},') }), t('') }
                ),
                c(
                    6,
                    { sn(nil, { t({ '', '  month        = {' }), i(1), t('},') }), t('') }
                ),
                i(7),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'phd', dscr = 'PhD Thesis' },
        fmta(
            [[
            @PhDThesis{<><>,
              author       = {<>},
              title        = {<>},
              institution  = {<>},
              address      = {<>},
              year         = {<>},
            }
            ]],
            {
                f(bibkey, { 1 }),
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
