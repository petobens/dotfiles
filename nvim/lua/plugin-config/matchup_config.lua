-- Helpers
local markdown_match_words = table.concat({
    -- Colon containers
    [=[^\s*\zs\:\{3}\:*\ze\%(\s\+\S\|{\):^\s*\zs\:\{3}\:*\ze\s*$]=],
    -- MyST display math with a closing equation label
    [=[^\s*\zs\$\$\ze\s*$:\$\$\ze\s\+(eq\:[^)]\+)\s*$]=],
    -- Display math with content on the opening line
    [=[^\s*\zs\$\$\ze\S:\$\$\ze\s*$]=],
    -- Labeled code fences
    [=[^\s*\zs`\{3}`*\ze\%(\s\+\S\|\w\):^\s*\zs`\{3}`*\ze\s*$]=],
    [=[^\s*\zs\~\{3}\~*\ze\%(\s\+\S\|\w\):^\s*\zs\~\{3}\~*\ze\s*$]=],
}, ',')

local function configure_markdown(args)
    if vim.bo[args.buf].filetype ~= 'markdown' then
        return
    end
    vim.b[args.buf].matchup_treesitter_enabled = false
    vim.b[args.buf].match_words = markdown_match_words
    vim.api.nvim_buf_call(args.buf, function()
        vim.fn['matchup#loader#init_buffer']()
    end)
end

-- Mappings
vim.keymap.set(
    { 'n', 'v', 'o' },
    '<tab>',
    '%',
    { remap = true, desc = 'Jump to next matching pair' }
)
vim.keymap.set(
    { 'n', 'v', 'o' },
    '<s-tab>',
    'g%',
    { remap = true, desc = 'Jump to previous matching pair' }
)

-- Autocmds
vim.api.nvim_create_autocmd('BufEnter', {
    desc = 'Matchup: configure Markdown delimiters',
    callback = configure_markdown,
})
