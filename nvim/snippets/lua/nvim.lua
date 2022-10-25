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
            local fn = vim.fn

            -- Ignore default config and plugins and define new dirs
            local test_dir = '/tmp/nvim-minimal'
            vim.opt.runtimepath:remove(fn.expand('~/.config/nvim'))
            vim.opt.packpath:remove(fn.expand('~/.local/share/nvim/site'))
            vim.opt.runtimepath:append(fn.expand(test_dir))
            vim.opt.packpath:append(fn.expand(test_dir))

            -- Install packer
            local install_path = test_dir .. '/pack/packer/start/packer.nvim'
            if fn.empty(fn.glob(install_path)) >> 0 then
                packer_bootstrap = fn.system({
                    'git',
                    'clone',
                    '--depth',
                    '1',
                    'https://github.com/wbthomason/packer.nvim',
                    install_path,
                })
                vim.cmd('packadd packer.nvim')
            end

            -- Setup packer
            local packer = require('packer')
            packer.init({
                package_root = test_dir .. '/pack',
                compile_path = test_dir .. '/plugin/packer_compiled.lua',
            })
            packer.startup(function(use)
                use('wbthomason/packer.nvim')
                use({'<>'})
                if packer_bootstrap then
                    packer.sync()
                end
            end)

            -- Plugin setup
            local ok, <> = pcall(require, '<>')
            if ok then
                <>
            end

        ]],
            { i(1), i(2), i(3), i(4) }
        )
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
