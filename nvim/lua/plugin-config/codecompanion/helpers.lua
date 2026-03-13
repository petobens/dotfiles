local codecompanion = require('codecompanion')
local config = require('codecompanion.config')

local adapter_config = require('plugin-config.codecompanion.adapters')

local M = {
    state = {},
    chat = {},
    window = {},
    files = {},
    git = {},
}

-- State
function M.state.get_last_chat()
    local ok, chat = pcall(codecompanion.last_chat)
    if ok and chat then
        return chat
    end
    return nil
end

function M.chat.get_or_create_chat()
    return M.state.get_last_chat() or codecompanion.chat()
end

function M.state.get_current_system_role_prompt()
    local chat = M.state.get_last_chat()
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

function M.state.get_last_user_prompt()
    local chat = M.state.get_last_chat()
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

function M.state.get_cycle_count()
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    return metadata.cycles or 0
end

function M.state.format_context_usage(adapter)
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    local tokens = metadata.tokens or 0
    local max_ctx = adapter_config.MODEL_CONTEXT_WINDOWS[adapter.schema.model.default]

    if not max_ctx then
        return string.format('unknown ctx (%d)', tokens)
    end

    return string.format('%.1f%% (%d)', (tokens / max_ctx) * 100, tokens)
end

-- Chat
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

-- Filesystem
function M.files.resolve_absolute_paths(files, root)
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

function M.files.detect_majority_filetype(files)
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
function M.git.find_root()
    local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true })
        :wait()
    local output = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

    if result.code ~= 0 or not output[1] or output[1] == '' then
        return nil, 'Not inside a Git repository. Could not determine the project root.'
    end

    return output[1]
end

function M.git.find_root_or_notify()
    local git_root, err = M.git.find_root()
    if not git_root then
        vim.notify(err, vim.log.levels.ERROR)
        return nil
    end

    return git_root
end

function M.git.resolve_diff_and_filelist_cmds(opts)
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

function M.git.collect_changed_files(git_root, file_list_cmd)
    local result = vim.system(file_list_cmd, { text = true, cwd = git_root }):wait()
    local files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

    if #files == 0 or (#files == 1 and files[1] == '') then
        return {}, 'No relevant files found'
    end

    return M.files.resolve_absolute_paths(files, git_root)
end

function M.git.build_diff_context(opts)
    local git_root = M.git.find_root_or_notify()
    if not git_root then
        return nil
    end

    local diff_cmd, file_list_cmd, cmd_err = M.git.resolve_diff_and_filelist_cmds(opts)
    if not diff_cmd then
        vim.notify(cmd_err, vim.log.levels.ERROR)
        return nil
    end

    local abs_files, file_err = M.git.collect_changed_files(git_root, file_list_cmd)
    if file_err then
        vim.notify(file_err, vim.log.levels.WARN)
        return nil
    end

    return {
        git_root = git_root,
        diff_cmd = diff_cmd,
        abs_files = abs_files,
    }
end

function M.git.find_release_commit_shas(git_root)
    local tag = vim.trim(
        vim.system(
            { 'git', 'describe', '--tags', '--abbrev=0' },
            { text = true, cwd = git_root }
        )
            :wait().stdout or ''
    )
    if tag == '' then
        vim.notify('No release tag found!', vim.log.levels.WARN)
        return nil
    end

    local shas = vim.split(
        vim.trim(
            vim.system(
                { 'git', 'log', '--format=%H', tag .. '..HEAD' },
                { text = true, cwd = git_root }
            )
                :wait().stdout or ''
        ),
        '\n',
        { plain = true }
    )

    if vim.tbl_isempty(shas) or (#shas == 1 and shas[1] == '') then
        vim.notify('No commits found after latest release!', vim.log.levels.WARN)
        return nil
    end

    return shas
end

return M
