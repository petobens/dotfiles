local extras = require('luasnip.extras')
local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

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
              pages   = {<>}
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
}, {}
