local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

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
                '<>'
            }
            require('lazy').setup(plugins, {
                root = root .. '/plugins',
            })


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
                local <> = vim.api.nvim_create_augroup('<>', { clear = true })
                vim.api.nvim_create_autocmd({'<>'}, {
                    group = <>,
                    <>
                })
            ]],
            {
                i(1, 'acg_var'),
                i(2, 'group_name'),
                i(3, 'event'),
                rep(1),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
}, {}
