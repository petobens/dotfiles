local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local rep = extras.rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Theorems, propositions, etc
    s(
        { trig = 'thm', dscr = '[Th]eore[m]' },
        fmta(
            [[
      \begin{theorem}<>
      \label{thm:<>}
        <><>
      \end{theorem}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                i(2, 'label'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uthm', dscr = '[U]nnumbered [th]eore[m]' },
        fmta(
            [[
      \begin{theorem*}<>
        <><>
      \end{theorem*}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pro', dscr = '[Pro]position' },
        fmta(
            [[
      \begin{proposition}
      \label{pro:<>}
        <><>
      \end{proposition}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'upro', dscr = '[U]nnumbered [pro]position' },
        fmta(
            [[
      \begin{proposition*}
        <><>
      \end{proposition*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'lem', dscr = '[Lem]ma' },
        fmta(
            [[
      \begin{lemma}<>
      \label{lem:<>}
        <><>
      \end{lemma}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                i(2, 'label'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ulem', dscr = '[U]nnumbered [lem]ma' },
        fmta(
            [[
      \begin{lemma*}<>
        <><>
      \end{lemma*}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cor', dscr = '[Cor]ollary' },
        fmta(
            [[
      \begin{corollary}
      \label{cor:<>}
        <><>
      \end{corollary}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ucor', dscr = '[U]nnumbered [cor]ollary' },
        fmta(
            [[
      \begin{corollary*}
        <><>
      \end{corollary*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'def', dscr = '[Def]inition' },
        fmta(
            [[
      \begin{definition}
      \label{def:<>}
        <><>
      \end{definition}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'udef', dscr = '[U]nnumbered [def]inition' },
        fmta(
            [[
      \begin{definition*}
        <><>
      \end{definition*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exa', dscr = '[Exa]mple' },
        fmta(
            [[
      \begin{example}
      \label{exa:<>}
        <><>
      \end{example}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uexa', dscr = '[U]nnumbered [exa]mple' },
        fmta(
            [[
      \begin{example*}
        <><>
      \end{example*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exac', dscr = '[Exa]mple [c]ontinued' },
        fmta(
            [[
      \begin{examcont}{exa:<>}
        <><>
      \end{examcont}
    ]],
            {
                i(1, 'ref'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exe', dscr = '[Exe]rcise' },
        fmta(
            [[
      \begin{exercise}
      \label{exe:<>}
        <><>
      \end{exercise}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uexe', dscr = '[U]nnumbered [exe]rcise' },
        fmta(
            [[
      \begin{exercise*}
        <><>
      \end{exercise*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ps', dscr = '[P]roblem [s]tatement' },
        fmta(
            [[
      \begin{problem*}
        <><>
      \end{problem*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ans', dscr = '[Ans]wer/Solution' },
        fmta(
            [[
      \begin{solution*}
        <><>
      \end{solution*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rem', dscr = '[Rem]ark' },
        fmta(
            [[
      \begin{remark}
      \label{rem:<>}
        <><>
      \end{remark}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'urem', dscr = '[U]nnumbered [rem]ark' },
        fmta(
            [[
      \begin{remark*}
        <><>
      \end{remark*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'not', dscr = '[Not]ation' },
        fmta(
            [[
      \begin{notation*}
        <><>
      \end{notation*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pru', dscr = '[Pru]eba/proof' },
        fmta(
            [[
      \begin{proof}<>
        <><>
      \end{proof}
    ]],
            {
                c(1, {
                    sn(nil, {
                        t('['),
                        i(1, 'Prueba de '),
                        t([[\cref*{]]),
                        i(2, 'thm:'),
                        t('}]'),
                    }),
                    t(''),
                }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),

    -- Equation Environments
    s(
        { trig = 'equ', dscr = '[Equ]ation' },
        fmta(
            [[
      \begin{equation}
      \label{eq:<>}
        <><>
      \end{equation}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ueq', dscr = '[U]nnumbered [eq]uation' },
        fmta(
            [[
      \begin{equation*}
        <><>
      \end{equation*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'be', dscr = '[B]reakable [e]quation' },
        fmta(
            [[
      \begin{dmath*}
        <><>
      \end{dmath*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ali', dscr = '[Ali]gn' },
        fmta(
            [[
      \begin{align}
        <><first_eq> <>\\
        <second_eq> <>
      \end{align}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                first_eq = i(2, 'first eq'),
                c(3, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                second_eq = i(4, 'second eq'),
                c(5, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sit', dscr = '[S]hort [i]n[t]ertext' },
        fmta(
            [[
        \<>intertext{<>}
    ]],
            {
                c(1, { sn(nil, { i(1, 'short') }), t('') }),
                i(2),
            }
        ),
        { condition = line_begin }
    ),

    s(
        { trig = 'ua', dscr = '[U]nnumbered [a]lign' },
        fmta(
            [[
      \begin{align*}
        <><> \\
        <>
      \end{align*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2, 'first eq'),
                i(3, 'second eq'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'max', dscr = '[Max]/min' },
        fmta(
            [[
      \begin{alignat}{2}
        & \<max>_{\{<variable>\}} & \, <func> <func_label>\\
        & \;\; \text{<sa>} & <constraint_1> <c1_label>\\
        & & <constraint_2> <c2_label>
      \end{alignat}
    ]],
            {
                max = c(1, { sn(nil, { i(1, 'max') }), t('min') }),
                variable = i(2),
                func = i(3, 'F(x,y) & = xy'),
                func_label = c(4, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                sa = c(5, { sn(nil, { i(1, 's.a') }), t('s.t') }),
                constraint_1 = i(6, 'constraint with &'),
                c1_label = c(7, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                constraint_2 = i(8, 'constraint with &'),
                c2_label = c(9, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
            }
        ),
        { condition = line_begin }
    ),

    -- Within Equation Environments
    s(
        { trig = 'aed', dscr = '[A]lign[ed]' },
        fmta(
            [[
      \begin{aligned}<>
        <><> \\
        <>
      \end{aligned}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'r'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3, 'first eq'),
                i(4, 'second eq'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dca', dscr = '[dca]ses environment' },
        fmta(
            [[
      \begin{dcases*}
        <> & <> $<>$ \\
        <> & <> $<>$
      \end{dcases*}
    ]],
            {
                i(1),
                c(2, { sn(nil, { i(1, 'if') }), t('si') }),
                i(3),
                i(4),
                rep(2),
                i(5),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mat', dscr = '[Mat]rix' },
        fmta(
            [[
      \begin{<>matrix*}<>
        <>
      \end{<>matrix*}
    ]],
            {
                c(1, { sn(nil, { i(1, 'p/b/v/V/B') }), t('') }),
                c(2, { sn(nil, { t('['), i(1, 'r'), t(']') }), t('') }),
                i(3),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),
}, {}
