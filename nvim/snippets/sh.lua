local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'case', dscr = 'Case' },
        fmta(
            [[
            case <> in
                <>)
                    <>
                    ;;
                **)
                    <>
                    ;;
            esac
                ]],
            { i(1, 'variable'), i(2, 'option'), i(3), i(4) }
        ),
        { condition = line_begin }
    ),
}, {}
