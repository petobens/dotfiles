-- Options (essentially disable most functionality)
vim.g.vimtex_compiler_enabled = 0
vim.g.vimtex_quickfix_enabled = 0
vim.g.vimtex_view_enabled = 0
vim.g.vimtex_complete_enabled = 0
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
vim.g.vimtex_indent_enabled = 0
vim.g.vimtex_imaps_enabled = 0
vim.g.vimtex_matchparen_enabled = 0
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

-- Mappings
local vimtex = vim.api.nvim_create_augroup('vimtex', { clear = true })
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vimtex,
    pattern = { 'tex' },
    command = 'nmap <buffer><silent> <Leader>tc <Plug>(vimtex-toc-open)',
})
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vimtex,
    pattern = { 'tex' },
    command = 'nmap <buffer><silent> <Leader>ce <Plug>(vimtex-env-change)',
})
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vimtex,
    pattern = { 'tex' },
    command = 'nmap <buffer><silent> <Leader>ts <Plug>(vimtex-env-toggle-star)',
})
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vimtex,
    pattern = { 'tex' },
    command = 'nmap <buffer><silent> <Leader>lr <Plug>(vimtex-delim-toggle-modifier)',
})
