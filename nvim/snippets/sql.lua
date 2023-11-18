local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Sqlfluff
    s(
        { trig = 'nq', dscr = 'Sqlfluff noqa' },
        fmta(
            [[
            -- noqa
        ]],
            {}
        )
    ),

    -- Postgres
    s(
        { trig = 'pgct', dscr = 'Postgres create table' },
        fmta(
            [[
            CREATE TABLE <><> (
              <> <> NOT NULL,
              <> <> NOT NULL
            );
            ]],
            {
                c(1, { t('IF NOT EXISTS '), t('') }),
                i(2, 'name'),
                i(3),
                i(4, 'varchar(20)'),
                i(5),
                i(6, 'integer'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pgi', dscr = 'Postgres insert' },
        fmta(
            [[
            INSERT INTO <> (<>)
            VALUES
            (<>),
            (<>);
            ]],
            { i(1), i(2), i(3), i(4) }
        ),
        { condition = line_begin }
    ),
}, {}
