-- Ensure image dir exists
local img_dir = vim.fs.joinpath(vim.env.HOME, 'Pictures', 'nvim-images')
if not vim.uv.fs_stat(img_dir) then
    vim.fn.mkdir(img_dir, 'p')
end

-- Setup
require('img-clip').setup({
    default = {
        dir_path = img_dir,
        use_absolute_path = true,
        prompt_for_file_name = false,
    },
    filetypes = {
        markdown = {
            template = '![$CURSOR]($FILE_PATH)',
        },
        codecompanion = {
            template = '[Image]($FILE_PATH)',
        },
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>pi', '<Cmd>PasteImage<CR>')
