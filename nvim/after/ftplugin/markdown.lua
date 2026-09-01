-- Options
vim.opt_local.foldlevel = 2
vim.opt_local.foldlevelstart = 1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.formatoptions = 'trjw'
vim.opt_local.comments = {}

-- Highlight containers, options, and equation roles missing from the parser
local namespace = vim.api.nvim_create_namespace('markdown_extensions')

local function highlight_range(bufnr, row, group, start_col, end_col)
    vim.hl.range(bufnr, namespace, group, { row, start_col }, { row, end_col })
end

local function highlight_extensions(args)
    local bufnr = args.buf
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    for row, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local indent, token = line:match('^(%s*)(:::+.*)$')
        local group = 'PreProc'
        if not token then
            indent, token = line:match('^(%s*)(:[%w_-]+:)')
            group = '@property'
        end
        if token then
            highlight_range(bufnr, row - 1, group, #indent, #indent + #token)
        end

        for first, last in line:gmatch('(){eq}`[^`]+`()') do
            highlight_range(bufnr, row - 1, 'Number', first - 1, last - 1)
        end
    end
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
    buffer = 0,
    desc = 'Highlight Markdown extension syntax',
    callback = highlight_extensions,
})
