local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Functions
local function get_comment_string()
    ---@diagnostic disable-next-line: missing-parameter
    return vim.trim(vim.split(vim.bo.cms, '%%s')[1])
end

local function visual_selection(_, snip)
    return snip.env.TM_SELECTED_TEXT or {}
end

return {
    s({ trig = 'TD', dscr = 'Todo' }, {
        f(get_comment_string),
        t(' TODO: '),
        f(visual_selection),
        i(0),
    }),
    s({ trig = 'FM', dscr = 'Fixme' }, {
        f(get_comment_string),
        t(' FIXME: '),
        f(visual_selection),
        i(0),
    }),
}, {
    -- Autosnippets
    ---- "Abolish" type spelling mistakes
    s('anio', { t('año') }),
    s('campaing', { t('campaign') }),
    s('teh', { t('the') }),
    s('widht', { t('width') }),

    ---- Autopairs
    s({ trig = 'dq', dscr = 'Double quotes' }, {
        t('"'),
        f(visual_selection),
        i(1),
        t('"'),
        i(0),
    }),
    s({ trig = 'sq', dscr = 'Single quotes' }, {
        t("'"),
        f(visual_selection),
        i(1),
        t("'"),
        i(0),
    }),
    s({ trig = '{{', wordTrig = false, dscr = 'Braces' }, {
        t('{'),
        f(visual_selection),
        i(1),
        t('}'),
        i(0),
    }),
    s({ trig = '((', wordTrig = false, dscr = 'Parenthesis' }, {
        t('('),
        f(visual_selection),
        i(1),
        t(')'),
        i(0),
    }),
    s({ trig = '[[', wordTrig = false, dscr = 'Brackets' }, {
        t('['),
        f(visual_selection),
        i(1),
        t(']'),
        i(0),
    }),

    s({ trig = '<<', wordTrig = false, dscr = '<>' }, {
        t('<'),
        f(visual_selection),
        i(1),
        t('>'),
        i(0),
    }),
}
