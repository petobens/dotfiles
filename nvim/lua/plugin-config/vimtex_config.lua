-- Vim TeX global options
vim.g.tex_flavor = 'latex' -- treat latex files .tex files rather than plaintex
vim.g.tex_conceal = nil

-- Vimtex options
---- Compiler & Completion
vim.g.vimtex_compiler_enabled = 0
vim.g.vimtex_compiler_method = 'arara'
vim.g.vimtex_quickfix_enabled = 0
vim.g.vimtex_view_enabled = 0
vim.g.vimtex_complete_enabled = 0
---- Folding
vim.g.vimtex_fold_enabled = 1
vim.g.vimtex_fold_manual = 1 -- only compute folds on demand
vim.g.vimtex_fold_types = { -- only fold preamble, parts and sections
    preamble = { enabled = 1 },
    sections = { enabled = 1 },
    parts = { enabled = 1 },
    comments = { enabled = 0 },
    envs = { whitelist = { 'frame', 'abstract' } },
    env_options = { enabled = 0 },
    items = { enabled = 0 },
    markers = { enabled = 0 },
    cmd_single = { enabled = 0 },
    cmd_single_opt = { enabled = 0 },
    cmd_multi = { enabled = 0 },
    cmd_addplot = { enabled = 0 },
}
----- Indent & delimiters
vim.g.vimtex_indent_enabled = 0
vim.g.vimtex_matchparen_enabled = 0
---- TOC
vim.g.vimtex_toc_config = {
    split_pos = 'vert topleft',
    split_width = 40,
    mode = 1,
    fold_enable = 1,
    fold_level_start = -1,
    show_help = 0,
    resize = 0,
    show_numbers = 1,
    layer_status = { label = 0, include = 0, todo = 0, content = 1 },
    hide_line_numbers = 0,
    tocdepth = 2,
    indent_levels = 1,
}
vim.g.vimtex_toc_show_preamble = 0
-- Docs
vim.g.vimtex_doc_confirm_single = 0

-- Mappings
vim.g.vimtex_imaps_enabled = 0
vim.api.nvim_create_autocmd({ 'User' }, {
    group = vim.api.nvim_create_augroup('vimtex_maps', { clear = true }),
    pattern = { 'VimtexEventInitPost' },
    callback = function(e)
        local vimtex_maps = { buffer = e.buf, remap = true }
        vim.keymap.set('n', '<Leader>tc', '<plug>(vimtex-toc-open)', vimtex_maps)
        vim.keymap.set('n', '<Leader>ce', '<plug>(vimtex-env-change)', vimtex_maps)
        vim.keymap.set('n', '<Leader>ts', '<plug>(vimtex-env-toggle-star)', vimtex_maps)
        vim.keymap.set(
            'n',
            '<Leader>td',
            '<plug>(vimtex-delim-toggle-modifier)',
            vimtex_maps
        )
        vim.keymap.set('i', '<A-d>', '<plug>(vimtex-delim-close)', vimtex_maps)
        vim.keymap.set('n', 'vim', 'vi$', vimtex_maps)
        vim.keymap.set('n', 'vam', 'va$', vimtex_maps)
        vim.keymap.set(
            'n',
            '<Leader>cw',
            '<Cmd>VimtexCountWords!<CR><Cmd>wincmd J<bar>12 wincmd _<CR>'
                .. '<Cmd>silent! normal! G<CR>',
            { buffer = e.buf }
        )
        vim.keymap.set('n', '<Leader>vd', '<Cmd>VimtexDocPackage<CR>', { buffer = e.buf })
        vim.keymap.set('n', '<Leader>vm', require('nabla').popup, { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        group = vim.api.nvim_create_augroup('vimtex_folds', { clear = true }),
        pattern = { '*.tex' },
        callback = function()
            -- If a choice node is active then `zx` is inserted
            if not require('luasnip').choice_active() then
                vim.cmd('VimtexRefreshFolds')
            end
        end,
    }
)
