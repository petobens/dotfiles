local ls = require('luasnip')
local t = ls.text_node
local s = ls.snippet
local c = ls.choice_node
local sn = ls.snippet_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local visual_selection = function(_, snip)
    return snip.env.TM_SELECTED_TEXT[1] or {}
end

return {
    -- Control flow
    s(
        { trig = 'sb', dscr = 'Shebang (bash)' },
        fmta(
            [[
            #!/usr/bin/env bash
        ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fun', dscr = 'Function' },
        fmta(
            [[
                <>() {
                    <>
                }
            ]],
            { i(1, 'name'), i(2) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'if', dscr = 'Conditional' },
        fmta(
            [[
                if <>; then
                    <>
                fi
            ]],
            {
                c(1, {
                    sn(nil, { t('[[ '), i(1), t(' ]]') }),
                    sn(nil, { t('(('), i(1), t('))') }),
                    t(''),
                }),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'for', dscr = 'For loop' },
        fmta(
            [[
                for <>; do
                    <>
                done
            ]],
            {
                c(1, {
                    t(''),
                    sn(nil, { i(1, 'i'), t(' in "${'), i(2, 'array_name'), t('[@]}"') }),
                    sn(nil, { t('((i = 0; i < '), i(1, '10'), t('; i++))') }),
                }),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
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
    s(
        { trig = 'da', dscr = 'Declare associative array' },
        fmta(
            [[
                declare -A <>=(
                    [<>]=<>
                )
            ]],
            { i(1, 'array_name'), i(2, 'key'), i(3, 'value') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'vb', wordTrig = false, dscr = 'Variable' },
        fmta(
            [[
                "$<><>"
            ]],
            {
                i(1),
                f(visual_selection),
            }
        )
    ),
    s(
        { trig = 'arr', wordTrig = false, dscr = 'Array' },
        fmta(
            [[
                "${<>[<>]}"
            ]],
            {
                i(1, 'array_name'),
                i(2, '@'),
            }
        )
    ),
    -- Linting
    s(
        { trig = 'sd', dscr = 'Shellcheck disable' },
        fmta(
            [[
            # shellcheck disable=SC
        ]],
            {}
        )
    ),
}, {}
