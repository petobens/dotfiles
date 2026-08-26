local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local layout_strategies = require('telescope.pickers.layout_strategies')

local default_quickfix = require('telescope.make_entry').gen_from_quickfix({})

local M = {}

-- Layout
function M.setup()
    layout_strategies.bpane = function(picker, max_columns, max_lines, layout_config)
        local layout =
            layout_strategies.bottom_pane(picker, max_columns, max_lines, layout_config)
        layout.prompt.width = layout.results.width
        layout.prompt.col = layout.results.col
        if layout.preview then
            layout.preview.height = layout.preview.height + 2
        end
        return layout
    end

    -- Autocmds
    vim.api.nvim_create_autocmd('FileType', {
        desc = 'Telescope prompt customizations',
        group = vim.api.nvim_create_augroup('telescope_prompt', { clear = true }),
        pattern = { 'TelescopePrompt' },
        callback = function(e)
            local prompt_bufnr = e.buf

            vim.opt_local.cursorline = false
            vim.keymap.set('n', 'H', '^lll', { buf = prompt_bufnr })
            vim.keymap.set('n', 'L', '$', { buf = prompt_bufnr })

            vim.schedule(function()
                local picker = action_state.get_current_picker(prompt_bufnr)
                if not picker then
                    return
                end
                if picker.prompt_title == 'Images' then
                    vim.keymap.set('i', '<CR>', function()
                        actions.select_default(prompt_bufnr)
                    end, { buf = prompt_bufnr })
                end
            end)
        end,
    })
    vim.api.nvim_create_autocmd('User', {
        desc = 'Telescope previewer window customizations',
        group = vim.api.nvim_create_augroup('telescope_preview_ln', { clear = true }),
        pattern = { 'TelescopePreviewerLoaded' },
        callback = function(e)
            vim.opt_local.number = true
            vim.api.nvim_buf_set_name(e.buf, 'TelescopePreview' .. e.buf)
        end,
    })
end

-- Entry makers
function M.quickfix_entry_maker(item)
    local entry = default_quickfix(item)
    local default_display = entry.display
    entry.display = function(display_entry)
        local line, highlights = default_display(display_entry)
        local _, lnum_start, _, col_start, col = line:match('^(.-):()(%d+):()(%d+)')
        vim.list_extend(highlights, {
            { { 0, lnum_start - 2 }, 'Directory' },
            { { lnum_start - 1, col_start + #col - 1 }, 'TelescopeResultsNumber' },
        })
        return line, highlights
    end
    return entry
end

return M
