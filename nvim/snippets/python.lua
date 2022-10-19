local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta

local selected_text = function(_, snip)
    return snip.env.TM_SELECTED_TEXT[1] or {}
end

return {
    s(
        { trig = 'im', dscr = 'If main' },
        fmta(
            [[
               if __name__ == '__main__':
                    <>
            ]],
            { i(0) }
        )
    ),
}, {
    s({ trig = 'tq', dscr = 'Triple quotes' }, {
        t('"""'),
        f(selected_text, {}),
        i(1),
        t('"""'),
        i(0),
    }),
}
