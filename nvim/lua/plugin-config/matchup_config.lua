vim.g.matchup_matchparen_enabled = 0

vim.keymap.set({ 'n', 'v', 'o' }, '<tab>', '%', { remap = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<s-tab>', 'g%', { remap = true })
