local ls = require('luasnip')
local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function visual_selection(_, snip)
    return snip.env.TM_SELECTED_TEXT or {}
end

return {
    s(
        { trig = 'dd', dscr = 'Disable next line diagnostic' },
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
        { trig = 'mv', dscr = 'Minimal init' },
        fmta(
            [[

            local root = '/tmp/nvim-minimal'

            -- Set stdpaths to use root dir
            for _, name in ipairs({ 'config', 'data', 'state', 'cache' }) do
                vim.env[('XDG_%s_HOME'):format(name:upper())] = root .. '/' .. name
            end

            -- Bootstrap lazy
            local lazypath = root .. '/plugins/lazy.nvim'
            if not vim.loop.fs_stat(lazypath) then
                vim.fn.system({
                    'git',
                    'clone',
                    '--filter=blob:none',
                    '--single-branch',
                    'https://github.com/folke/lazy.nvim.git',
                    lazypath,
                })
            end
            vim.opt.runtimepath:prepend(lazypath)

            -- Install plugins
            local plugins = {
                { 'folke/tokyonight.nvim' },
                {'<>'},
            }
            require('lazy').setup(plugins, {
                root = root .. '/plugins',
            })
            vim.cmd.colorscheme('tokyonight')


        ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'acg', dscr = 'Autocmd group' },
        fmta(
            [[
                vim.api.nvim_create_autocmd({'<>'}, {
                    group = vim.api.nvim_create_augroup('<>', { clear = true }),
                    <>
                })
            ]],
            {
                i(1, 'Event'),
                i(2, 'Acg name'),
                c(3, { sn(nil, { t("pattern = {'"), i(1, '*'), t("'},") }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pp', dscr = 'Pretty print' },
        fmta(
            [[
                vim.print(<><>)<>
            ]],
            {
                f(visual_selection),
                i(1),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'km', dscr = 'Keymap' },
        fmta(
            [[
                u.keymap('<>', '<>', <><>)
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
