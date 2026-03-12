-- luacheck:ignore 631
local adapter_config = require('plugin-config.codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local telescope_action_state = require('telescope.actions.state')

local M = {
    chat = {},
    window = {},
    ui = {},
    files = {},
    git = {},
    diagnostics = {},
}

-- Chat state
function M.chat.get_last_chat()
    local ok, chat = pcall(codecompanion.last_chat)
    if ok and chat then
        return chat
    end
    return nil
end

function M.chat.get_or_create_chat()
    return M.chat.get_last_chat() or codecompanion.chat()
end

function M.chat.get_current_system_role_prompt()
    local chat = M.chat.get_last_chat()
    if not chat or type(chat.messages) ~= 'table' then
        return nil
    end

    local system_role = nil
    for _, entry in ipairs(chat.messages) do
        if entry.role == 'system' then
            system_role = entry.content
        end
    end

    return system_role
end

function M.chat.get_last_user_prompt()
    local chat = M.chat.get_last_chat()
    if not chat or type(chat.messages) ~= 'table' then
        return nil
    end

    for i = #chat.messages, 1, -1 do
        local msg = chat.messages[i]
        if msg.role == 'user' then
            return msg.content
        end
    end

    return nil
end

function M.chat.get_chat_cycles()
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    return metadata.cycles or 0
end

function M.chat.get_context_usage(adapter)
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    local tokens = metadata.tokens or 0
    local max_ctx = adapter_config.MODEL_CONTEXT_WINDOWS[adapter.schema.model.default]

    if not max_ctx then
        return string.format('unknown ctx (%d)', tokens)
    end

    return string.format('%.1f%% (%d)', (tokens / max_ctx) * 100, tokens)
end

function M.chat.add_context(files)
    local chat = M.chat.get_or_create_chat()

    for _, file in ipairs(files) do
        local fd = io.open(file, 'r')
        local content
        if fd then
            content = fd:read('*a')
            fd:close()
        end

        if not content then
            vim.notify('Could not read file: ' .. file, vim.log.levels.ERROR)
        else
            chat:add_context({
                role = 'user',
                content = string.format('Here is the content of %s:%s', file, content),
            }, 'file', string.format('<file>%s</file>', vim.fs.basename(file)))
        end
    end

    M.window.focus_or_toggle_chat({ startinsert = false })
end

function M.chat.run_slash_command(name, opts)
    opts = opts or {}

    local chat = M.chat.get_or_create_chat()
    local cmd = config.interactions.chat.slash_commands[name]

    if cmd and type(cmd.callback) == 'function' then
        cmd.callback(chat, opts)
        M.window.focus_or_toggle_chat({ startinsert = false })
    else
        vim.notify('Slash command not found: ' .. tostring(name), vim.log.levels.ERROR)
    end
end

-- Chat windows
function M.window.try_focus_chat_float()
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local conf = vim.api.nvim_win_get_config(win_id)
        if conf.focusable and conf.relative ~= '' and conf.zindex == 45 then
            vim.api.nvim_set_current_win(win_id)
            return true
        end
    end

    return false
end

function M.window.focus_or_toggle_chat(opts)
    opts = opts or {}
    local startinsert = opts.startinsert ~= false

    if M.window.try_focus_chat_float() then
        return
    end

    codecompanion.toggle()

    if startinsert then
        vim.defer_fn(function()
            vim.cmd.startinsert()
        end, 10)
    end
end

function M.window.toggle_cc_zoom()
    local win = vim.api.nvim_get_current_win()
    local win_config = vim.api.nvim_win_get_config(win)
    local saved = vim.w.cc_default_float_conf

    if saved then
        vim.api.nvim_win_set_config(win, saved)
        vim.w.cc_default_float_conf = nil
        return
    end

    vim.w.cc_default_float_conf = win_config
    vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        row = 1,
        col = math.floor(vim.o.columns * 0.10),
        width = math.floor(vim.o.columns * 0.80),
        height = vim.o.lines - 4,
    })
end

-- Chat UI
function M.ui.set_chat_win_title(e)
    local chatmap = {}
    local chats = codecompanion.buf_get_chat()

    for _, chat in pairs(chats) do
        chatmap[chat.chat.ui.winnr] = chat.name
    end

    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    end)

    if not ok then
        vim.defer_fn(function()
            local picker =
                telescope_action_state.get_current_picker(vim.api.nvim_get_current_buf())
            if picker then
                vim.api.nvim_win_close(picker.prompt_win, true)
            end
        end, 50)

        vim.wait(100)

        if vim.bo.filetype == 'codecompanion' then
            local win_id = vim.api.nvim_get_current_win()
            local current = vim.api.nvim_win_get_config(win_id)
            vim.api.nvim_win_set_config(win_id, {
                title = current.title[1][1]:gsub('%b()', '(' .. e.data.title .. ')'),
            })
        end
        return
    end

    vim.api.nvim_win_set_config(chat.ui.winnr, {
        title = string.format(
            'CodeCompanion - %s%s',
            chatmap[chat.ui.winnr],
            (chat.opts.title and chat.opts.title ~= '')
                    and string.format(' (%s)', chat.opts.title)
                or ''
        ),
        footer = string.format(
            '%s %s',
            vim.uv.cwd():match('([^/]+/[^/]+/[^/]+)$') or '',
            (chat.context.filename and chat.context.filename ~= '')
                    and ('(' .. vim.fs.basename(chat.context.filename) .. ')')
                or ''
        ),
        footer_pos = 'center',
    })
end

-- Filesystem
function M.files.to_absolute_paths(files, root)
    return vim.iter(files)
        :map(function(f)
            if f == '' then
                return nil
            end

            local abs_path = vim.fs.normalize(vim.fs.joinpath(root, f))
            local stat = vim.uv.fs_stat(abs_path)
            if stat and stat.type == 'file' then
                return abs_path
            end
            return nil
        end)
        :filter(function(f)
            return f ~= nil
        end)
        :totable()
end

function M.files.get_majority_filetype(files)
    local counts = {}
    local max_ft, max_count = nil, 0

    for _, file in ipairs(files) do
        local ft = vim.filetype.match({ filename = file })
        if ft and ft ~= '' then
            counts[ft] = (counts[ft] or 0) + 1
            if counts[ft] > max_count then
                max_count = counts[ft]
                max_ft = ft
            end
        end
    end

    if max_count > (#files / 2) then
        return max_ft
    end

    return nil
end

function M.files.send_project_tree(chat, root)
    local result = vim.system(
        { 'tree', '-a', '-L', '2', '--noreport', root },
        { text = true }
    )
        :wait()
    chat:add_message({
        role = 'user',
        content = string.format(
            'The project structure is given by:\n%s',
            result.stdout or ''
        ),
    })
end

-- Git
function M.git.git_root()
    local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true })
        :wait()
    local output = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

    if result.code ~= 0 or not output[1] or output[1] == '' then
        return nil, 'Not inside a Git repository. Could not determine the project root.'
    end

    return output[1]
end

function M.git.resolve_git_diff_and_filelist_cmds(opts)
    local diff_cmd = { 'git', 'diff', '--no-ext-diff' }
    local file_list_cmd = { 'git', 'diff', '--name-only' }

    if opts and opts.base_branch then
        local base = opts.base_branch
        local result = vim.system(
            { 'git', 'rev-parse', '--verify', base },
            { text = true }
        )
            :wait()
        if result.code ~= 0 then
            return nil, nil, 'Base branch not found: ' .. base
        end
        table.insert(diff_cmd, base .. '...HEAD')
        table.insert(file_list_cmd, base .. '...HEAD')
    elseif opts and opts.commit_sha then
        local sha = opts.commit_sha
        table.insert(diff_cmd, sha .. '^!')
        table.insert(file_list_cmd, sha .. '^!')
    else
        table.insert(diff_cmd, '--staged')
        table.insert(file_list_cmd, '--cached')
    end

    return diff_cmd, file_list_cmd
end

function M.git.get_git_files(git_root, file_list_cmd)
    local result = vim.system(file_list_cmd, { text = true, cwd = git_root }):wait()
    local files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

    if #files == 0 or (#files == 1 and files[1] == '') then
        return {}, 'No relevant files found'
    end

    return M.files.to_absolute_paths(files, git_root)
end

-- Diagnostics
function M.diagnostics.get_loclists_or_qf_entries()
    local diagnostics = {}

    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local loclist = vim.fn.getloclist(winid)
        if #loclist > 0 then
            vim.list_extend(diagnostics, loclist)
        end
    end

    if #diagnostics == 0 then
        diagnostics = vim.fn.getqflist()
    end

    local seen, entries, context = {}, {}, {}

    for _, item in ipairs(diagnostics) do
        local filename = vim.fs.basename(vim.api.nvim_buf_get_name(item.bufnr))
        local lnum = item.lnum or 0
        local col = item.col or 0
        local text = item.text or ''
        local key = table.concat({ filename, lnum, col, text }, '\0')

        if not seen[key] then
            seen[key] = true
            table.insert(
                entries,
                string.format('%s:%d:%d: %s', filename, lnum, col, text)
            )
            if filename ~= '' and not vim.tbl_contains(context, filename) then
                table.insert(context, filename)
            end
        end
    end

    return table.concat(entries, '\n'), context
end

return M
