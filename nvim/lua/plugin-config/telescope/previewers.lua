local actions = require('telescope.actions')
local from_entry = require('telescope.from_entry')
local telescope_previewers = require('telescope.previewers')

local image = require('image')

local M = {
    supported_images = {
        gif = true,
        jpeg = true,
        jpg = true,
        png = true,
        svg = true,
        webp = true,
    },
}

-- Terminal previewers
local function scroll_less(self, direction)
    if not self.state then
        return
    end
    local winid = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == self.state.termopen_bufnr then
            winid = win
            break
        end
    end
    if not winid then
        return
    end
    -- 0x05 -> <C-e>; 0x19 -> <C-y>
    local input = direction > 0 and string.char(0x05) or string.char(0x19)
    local count = math.abs(direction)
    vim.api.nvim_win_call(winid, function()
        vim.cmd.normal({ count .. input, bang = true })
    end)
end

M.tree = telescope_previewers.new_termopen_previewer({
    get_command = function(entry)
        return {
            'eza',
            '-F',
            '--tree',
            '--level=2',
            '--icons=always',
            '--color=always',
            from_entry.path(entry),
        }
    end,
    title = 'Tree Previewer',
    scroll_fn = scroll_less,
})

M.delta = telescope_previewers.new_termopen_previewer({
    get_command = function(entry)
        return {
            'git',
            '-c',
            'core.pager=delta',
            '-c',
            'delta.paging=never',
            '-c',
            'delta.side-by-side=false',
            'show',
            entry.value .. '^!',
            '--',
            entry.current_file,
        }
    end,
    title = 'Delta Diff',
    scroll_fn = scroll_less,
})

-- Image and PDF previewer
-- From https://github.com/3rd/image.nvim/issues/183#issuecomment-2284979815
local TELESCOPE_IMAGE_NAMESPACE = 'telescope-preview'
local state = { cleanup = nil, image = nil, request = 0 }

local function clear_preview()
    state.request = state.request + 1
    if state.cleanup then
        pcall(vim.api.nvim_del_autocmd, state.cleanup)
        state.cleanup = nil
    end
    if state.image then
        state.image:clear()
        state.image = nil
    end
    local previews = image.get_images({ namespace = TELESCOPE_IMAGE_NAMESPACE })
    for _, preview in ipairs(previews) do
        preview:clear()
    end
end

local function show_preview_image(path, bufnr, winid)
    local preview = image.from_file(path, {
        buffer = bufnr,
        window = winid,
        width = vim.api.nvim_win_get_width(winid),
        height = vim.api.nvim_win_get_height(winid),
        max_height_window_percentage = 100,
        namespace = TELESCOPE_IMAGE_NAMESPACE,
    })
    state.image = preview

    if preview then
        state.cleanup = vim.api.nvim_create_autocmd('BufWinLeave', {
            buffer = bufnr,
            once = true,
            desc = 'Clear Telescope image preview',
            callback = clear_preview,
        })

        vim.schedule(function()
            if
                state.image ~= preview
                or not vim.api.nvim_win_is_valid(winid)
                or vim.api.nvim_win_get_buf(winid) ~= bufnr
            then
                preview:clear()
                return
            end
            preview:render()
        end)
    end
end

function M.setup()
    actions.close:enhance({ pre = clear_preview })
end

function M.buffer_maker(filepath, bufnr, opts)
    clear_preview()
    local request = state.request

    local ext = vim.fs.ext(filepath):lower()
    if M.supported_images[ext] then
        local path = filepath:gsub(' ', '%%20'):gsub('\\', '')
        if opts.winid then
            show_preview_image(path, bufnr, opts.winid)
        end
    elseif ext == 'pdf' then
        vim.system(
            { 'pdftotext', '-layout', filepath, '-' },
            { text = true },
            function(obj)
                vim.schedule(function()
                    if
                        state.request ~= request or not vim.api.nvim_buf_is_valid(bufnr)
                    then
                        return
                    end

                    local output = obj.stdout or ''
                    if obj.code ~= 0 then
                        output = string.format(
                            'PDF preview failed (pdftotext exited with code %d)',
                            obj.code
                        )
                    end
                    local lines = vim.split(output, '\n', { plain = true })
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                end)
            end
        )
    else
        telescope_previewers.buffer_previewer_maker(filepath, bufnr, opts)
    end
end

return M
