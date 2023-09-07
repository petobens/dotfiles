local u = require('utils')

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
    tocdepth = 1,
}
-- FIXME: Not working: https://github.com/lervag/vimtex/issues/46#issuecomment-1710113952
vim.g.vimtex_toc_show_preamble = 0

-- Mappings
vim.g.vimtex_imaps_enabled = 0
vim.api.nvim_create_autocmd({ 'User' }, {
    group = vim.api.nvim_create_augroup('vimtex_maps', { clear = true }),
    pattern = { 'VimtexEventInitPost' },
    callback = function()
        local vimtex_maps = { buffer = true, remap = true }
        u.keymap('n', '<Leader>tc', '<plug>(vimtex-toc-open)', vimtex_maps)
        u.keymap('n', '<Leader>ce', '<plug>(vimtex-env-change)', vimtex_maps)
        u.keymap('n', '<Leader>ts', '<plug>(vimtex-env-toggle-star)', vimtex_maps)
        u.keymap('n', '<Leader>td', '<plug>(vimtex-delim-toggle-modifier)', vimtex_maps)
        u.keymap('i', '<A-d>', '<plug>(vimtex-delim-close)', vimtex_maps)
    end,
})
