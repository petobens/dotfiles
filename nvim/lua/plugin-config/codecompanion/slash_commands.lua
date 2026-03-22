local codecompanion = require('codecompanion')

local gws = require('plugin-config.codecompanion.tools.gws')
local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local file_helpers = require('plugin-config.codecompanion.helpers').files
local git_helpers = require('plugin-config.codecompanion.helpers').git
local prompt_library = require('plugin-config.codecompanion.prompt_library')

local M = {}

local ft_prompt_map = {
    lua = 'lua_role',
    python = 'python_role',
    sh = 'bash_role',
    sql = 'Sql_role',
    tex = 'latex_role',
}
local tmux_data = {}

-- Local helpers
local function collect_diagnostics_entries_and_context()
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

local function add_tmux_pane_context_incremental(chat, target)
    if not vim.env.TMUX then
        vim.notify('Not in a tmux session', vim.log.levels.ERROR)
        return
    end

    target = vim.trim(target or '')
    if target == '' or not target:match('^%d+%.%d+$') then
        vim.notify('Invalid target, use window.pane (e.g. 2.1)', vim.log.levels.ERROR)
        return
    end

    local result = vim.system({
        'tmux',
        'capture-pane',
        '-p',
        '-S',
        '-3000',
        '-E',
        '-',
        '-t',
        target,
    }, { text = true }):wait()

    local out = vim.trim(result.stdout or '')
    if result.code ~= 0 or out == '' then
        vim.notify('No tmux output captured for target: ' .. target, vim.log.levels.WARN)
        return
    end

    local lines = vim.split(out, '\n', { plain = true })
    local start_line = 1
    local prev = tmux_data[target]

    if prev and prev.lines then
        start_line = math.max(1, prev.lines - 3)
    end

    local new_lines = {}
    for i = start_line, #lines do
        table.insert(new_lines, lines[i])
    end

    tmux_data[target] = { lines = #lines }

    chat:add_context({
        role = 'user',
        content = ('Latest tmux output (%s):\n\n%s'):format(
            target,
            table.concat(new_lines, '\n')
        ),
    }, 'terminal', ('<tmux>%s</tmux>'):format(target))
end

-- Filesystem callbacks
local function file_path_callback()
    vim.ui.input({ prompt = 'File path: ', completion = 'file' }, function(file)
        local stat = file and vim.uv.fs_stat(file)
        if not (stat and stat.type == 'file') then
            vim.notify(string.format('File not found: %s', file), vim.log.levels.ERROR)
            return
        end

        chat_helpers.add_context({ file })
    end)
end

local function directory_callback(chat)
    vim.ui.input({ prompt = 'Context dir: ', completion = 'dir' }, function(dir)
        dir = vim.fs.normalize(vim.trim(dir)):gsub('/$', '')
        vim.cmd.redraw({ bang = true })

        local stat = vim.uv.fs_stat(dir)
        if not (stat and stat.type == 'directory') then
            vim.notify('Directory not found: ' .. dir, vim.log.levels.ERROR)
            return
        end

        local files = {}
        for name, ftype in vim.fs.dir(dir, { depth = math.huge }) do
            if ftype == 'file' then
                table.insert(files, vim.fs.joinpath(dir, name))
            end
        end

        file_helpers.send_project_tree(chat, dir)
        chat_helpers.add_context(files)
    end)
end

local function git_files_callback(chat)
    local git_root = git_helpers.find_root_or_notify()
    if not git_root then
        return
    end

    local result = vim.system({ 'git', 'ls-files' }, { text = true, cwd = git_root })
        :wait()
    local git_files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })
    local ignore_exts = { ['.png'] = true }
    local files = vim.iter(git_files)
        :filter(function(f)
            local ext = f:match('(%.[^%.]+)$') or ''
            return not ignore_exts[ext]
        end)
        :map(function(f)
            return vim.fs.joinpath(git_root, f)
        end)
        :totable()

    file_helpers.send_project_tree(chat, git_root)
    chat_helpers.add_context(files)
end

local function py_files_callback(chat)
    if vim.tbl_isempty(_G.PyVenv.active_venv) then
        vim.notify('No active Python virtual environment found.', vim.log.levels.ERROR)
        return
    end

    file_helpers.send_project_tree(chat, _G.PyVenv.active_venv.project_root)
    chat_helpers.add_context(_G.PyVenv.active_venv.project_files)
end

-- Google Workspace callbacks
local function add_google_workspace_context(chat, kind, item, tag)
    chat:add_context({
        role = 'user',
        content = string.format(
            'Here is the content of the Google %s "%s" (ID: %s):\n\n%s',
            kind,
            item.title,
            item.id,
            item.text
        ),
    }, 'url', string.format('<%s>%s</%s>', tag, item.title, tag))
end

local function google_doc_callback(chat)
    vim.ui.input({ prompt = 'Google Doc URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        local doc, err = gws.read_google_doc(input)
        if not doc then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        add_google_workspace_context(chat, 'Doc', doc, 'gdoc')
    end)
end

local function google_sheet_callback(chat)
    vim.ui.input({ prompt = 'Google Sheet URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        vim.ui.input({ prompt = 'Sheet range: ', default = 'A1:Z200' }, function(range)
            if range == nil then
                return
            end

            local sheet, err = gws.read_google_sheet(
                input,
                vim.trim(range) ~= '' and vim.trim(range) or nil
            )
            if not sheet then
                vim.notify(err, vim.log.levels.ERROR)
                return
            end

            add_google_workspace_context(chat, 'Sheet', sheet, 'gsheet')
        end)
    end)
end

local function google_slides_callback(chat)
    vim.ui.input({ prompt = 'Google Slides URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        local slides, err = gws.read_google_slides(input)
        if not slides then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        add_google_workspace_context(chat, 'Slides presentation', slides, 'gslides')
    end)
end

-- Git callbacks
local function conventional_commit_callback(chat, opts)
    local ctx = git_helpers.build_diff_context(opts)
    if not ctx then
        return
    end

    chat_helpers.add_context(ctx.abs_files)

    local commit_history = vim.trim(
        vim.system(
            { 'git', 'log', '-n', '50', '--pretty=format:%s' },
            { text = true, cwd = ctx.git_root }
        )
            :wait().stdout or ''
    )

    local diff_output = vim.system(ctx.diff_cmd, { text = true, cwd = ctx.git_root })
        :wait().stdout or ''

    chat:add_buf_message({
        role = 'user',
        content = string.format(
            prompt_library.prompt('conventional_commits'),
            commit_history,
            diff_output
        ),
    })
    chat:submit()
end

local function code_review_callback(_, opts)
    local ctx = git_helpers.build_diff_context(opts)
    if not ctx then
        return
    end

    local ft = file_helpers.detect_majority_filetype(ctx.abs_files)
    local prompt_alias = ft_prompt_map[ft] or 'assistant_role'
    codecompanion.prompt(prompt_alias)

    local chat = chat_helpers.get_or_create_chat()
    chat_helpers.add_context(ctx.abs_files)

    local diff_output = vim.system(ctx.diff_cmd, { text = true, cwd = ctx.git_root })
        :wait().stdout or ''
    chat:add_buf_message({
        role = 'user',
        content = string.format(prompt_library.prompt('code_reviewer'), diff_output),
    })
    chat:submit()
end

local function changelog_callback(chat, opts)
    local git_root = git_helpers.find_root_or_notify()
    if not git_root then
        return
    end

    local shas = opts and opts.commit_shas
    if not shas or vim.tbl_isempty(shas) then
        shas = git_helpers.find_release_commit_shas(git_root)
        if not shas then
            return
        end
    end

    local commit_msgs = {}
    for _, sha in ipairs(shas) do
        local msg = vim.trim(
            vim.system(
                { 'git', 'show', '--no-patch', '--format=%B', sha },
                { text = true, cwd = git_root }
            )
                :wait().stdout or ''
        )
        table.insert(commit_msgs, msg:gsub('\n\n+', '\n\n'))
    end

    local changelog_file = vim.fs.joinpath(git_root, 'CHANGELOG.md')
    local stat = vim.uv.fs_stat(changelog_file)
    if stat and stat.type == 'file' then
        chat_helpers.add_context({ changelog_file })
    end

    chat:add_buf_message({
        role = 'user',
        content = string.format(
            prompt_library.prompt('changelog_generator'),
            table.concat(commit_msgs, '\n---\n')
        ),
    })
    chat:submit()
end

-- Coding callbacks
local function qfix_callback(chat)
    local entries, context = collect_diagnostics_entries_and_context()
    if entries == '' then
        vim.notify(
            'No diagnostics found in quickfix or location lists.',
            vim.log.levels.ERROR
        )
        return
    end

    chat_helpers.add_context(context)
    chat:add_buf_message({
        role = 'user',
        content = string.format(prompt_library.prompt('quickfix'), entries),
    })
    chat:submit()
end

local function explain_code_callback(chat, opts)
    local bufnr = opts and opts.bufnr
    local code = opts and opts.code
    local file = vim.api.nvim_buf_get_name(bufnr)
    local ft = vim.bo[bufnr].filetype ~= '' and vim.bo[bufnr].filetype or 'text'

    chat_helpers.add_context({ file })
    chat:add_buf_message({
        role = 'user',
        content = string.format(prompt_library.prompt('explain_code'), ft, code),
    })
    chat:submit()
end

-- Terminal callbacks
local function tmux_callback(chat)
    vim.ui.input({ prompt = 'tmux window.pane (default 1.2): ' }, function(target)
        target = vim.trim(target or '')
        if target == '' then
            target = '1.2'
        end
        add_tmux_pane_context_incremental(chat, target)
    end)
end

-- Slash command assembly
function M.build()
    return {
        -- Built-in
        ['help'] = { opts = { max_lines = 10000 } },
        ['image'] = {
            opts = {
                dirs = { '~/Pictures/Screenshots/' },
            },
        },
        -- Filesystem
        ['file_path'] = {
            description = 'Insert a filepath',
            keymaps = { modes = { n = '<C-f>', i = '<C-f>' } },
            callback = file_path_callback,
        },
        ['directory'] = {
            description = 'Insert all files in a directory',
            callback = directory_callback,
        },
        ['git_files'] = {
            description = 'Insert all files in git repo',
            callback = git_files_callback,
        },
        ['py_files'] = {
            description = 'Insert all project python files',
            callback = py_files_callback,
        },
        -- Google Workspace
        ['gdoc'] = {
            description = 'Read a Google Doc via gws',
            callback = google_doc_callback,
        },
        ['gsheet'] = {
            description = 'Read a Google Sheet via gws',
            callback = google_sheet_callback,
        },
        ['gslides'] = {
            description = 'Read a Google Slides presentation via gws',
            callback = google_slides_callback,
        },
        -- Git
        ['conventional_commit'] = {
            description = 'Generate a conventional git commit message',
            callback = conventional_commit_callback,
        },
        ['code_review'] = {
            description = 'Perform a code review',
            callback = code_review_callback,
        },
        ['changelog'] = {
            description = 'Generate a changelog entry from selected commits',
            callback = changelog_callback,
        },
        -- Coding
        ['qfix'] = {
            description = 'Explain quickfix/loclist code diagnostics',
            callback = qfix_callback,
        },
        ['explain_code'] = {
            description = 'Explain selected code',
            callback = explain_code_callback,
        },
        -- Terminal
        ['tmux'] = {
            description = 'Add tmux pane output (window.pane) as context',
            callback = tmux_callback,
        },
    }
end

return M
