local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    -- Luasnip
    s({ trig = 'snip', dscr = 'Snippet definition' }, {
        t({ "s({ trig = '" }),
        i(1, 'trigger'),
        t("', dscr = '"),
        i(2, 'description'),
        t({ "' }, {", '\t' }),
        i(3, 'snippet body'),
        t({ ',', '})' }),
    }),
    s({ trig = 'vis', dscr = 'Visual snippet' }, {
        t({
            'f(function(_, snip)',
            '\treturn snip.env.TM_SELECTED_TEXT[',
        }),
        i(1, '1'),
        t({
            '] or {}',
            'end, {}),',
        }),
    }),

    -- Lua
    s({ trig = 'rq', dscr = 'Require' }, {
        t("require('"),
        i(1, 'package'),
        t("')"),
        i(0),
    }),
    s({ trig = 'lv', dscr = 'Local variable' }, {
        t('local '),
        i(1, 'variable'),
        t(' = '),
        i(2, 'value'),
    }),
    s({ trig = 'if', dscr = 'If condition' }, {
        t('if '),
        i(1, 'condition'),
        t({ ' then', '\t' }),
        i(2, 'body'),
        t({ '', 'end' }),
        i(0),
    }),
    s({ trig = 'ef', dscr = 'Empty function' }, {
        t({ 'function()', '\t' }),
        i(1),
        t({ '', 'end' }),
        i(0),
    }),
    s({ trig = 'lf', dscr = 'Local function definition' }, {
        t('local '),
        i(1, 'fun_name'),
        t(' = function('),
        i(2),
        t({ ')', '\t' }),
        i(3),
        t({ '', 'end' }),
        i(0),
    }),
    s({ trig = 'fun', dscr = 'Function definition' }, {
        t('function '),
        i(1, 'fun_name'),
        t('('),
        i(2),
        t({ ')', '\t' }),
        i(3),
        t({ '', 'end' }),
        i(0),
    }),
},
    {}
