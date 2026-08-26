-- luacheck:ignore 631
local ls = require('luasnip')
local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'dd', dscr = '[D]isable next line [d]iagnostic' },
        fmta(
            [[
               ---@diagnostic disable-next-line: <>
            ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'mv', dscr = '[M]inimal N[v]im init' },
        fmta(
            [[

            local root = vim.fs.joinpath(vim.env.TMPDIR or '/tmp', 'nvim-minimal')

            -- Set stdpaths to use root dir
            for _, name in ipairs({ 'config', 'data', 'state', 'cache' }) do
                vim.env[('XDG_%s_HOME'):format(name:upper())] = vim.fs.joinpath(root, name)
            end
            vim.opt.packpath:prepend(vim.fs.joinpath(vim.env.XDG_DATA_HOME, 'nvim', 'site'))
            vim.opt.packlockfile =
                vim.fs.joinpath(vim.env.XDG_CONFIG_HOME, 'nvim', 'nvim-pack-lock.json')

            -- Install plugins
            vim.pack.add({
                'https://github.com/folke/tokyonight.nvim',
                '<>',
            }, { confirm = false, load = true })
            vim.cmd.colorscheme('tokyonight')

        ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'auc', dscr = '[Au]to[c]md' },
        fmta(
            [[
                vim.api.nvim_create_autocmd({'<>'}, {
                    group = vim.api.nvim_create_augroup('<>', { clear = true }),<>
                    callback = function()
                        <>
                    end
                })
            ]],
            {
                i(1, 'Event'),
                i(2, 'Acg name'),
                c(3, {
                    sn(nil, { t({ '', "    pattern = {'" }), i(1, '*'), t("'},") }),
                    t(''),
                }),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cc', dscr = '[C]reate user [c]ommand' },
        fmta(
            [[
                vim.api.nvim_create_user_command({'<>'}, function()
                    <>
                end, { <> })
            ]],
            {
                i(1, 'CommandName'),
                i(2),
                i(3, 'nargs = 1, range = true'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pp', dscr = '[P]retty [p]rint' },
        fmta(
            [[
                vim.print(<><>)<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'km', dscr = '[K]ey[m]ap' },
        fmta(
            [[
                vim.keymap.set('<>', '<>', <><>)
            ]],
            {
                i(1, 'n'),
                i(2),
                i(3),
                c(4, { sn(nil, { t(', {'), i(1), t('}') }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
}, {}
