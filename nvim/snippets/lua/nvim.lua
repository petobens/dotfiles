local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin
local sn = ls.snippet_node
local c = ls.choice_node
local t = ls.text_node
local d = ls.dynamic_node

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
                use('wbthomason/packer.nvim')<>
                if packer_bootstrap then
                    packer.sync()
                end
            end)<>
        ]],
            {
                c(1, {
                    sn(nil, {
                        t({ '', "\tuse({'" }),
                        i(1, 'package'),
                        t("'})"),
                    }),
                    t(''),
                }),
                d(2, function(node_idx)
                    local snip_body = {}
                    local node_val = node_idx[1][2]
                    if node_val then
                        snip_body = {
                            t({ '', '', '-- Plugin setup', 'local ok, ' }),
                            i(1),
                            t({ " = pcall(require, '" }),
                            i(2),
                            t({ "')", 'if ok then', '\t' }),
                            i(3),
                            t({ '', 'end' }),
                        }
                    end
                    return sn(nil, snip_body)
                end, { 1 }),
            }
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
