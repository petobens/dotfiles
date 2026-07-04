local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local repo_helpers = require('plugin-config.codecompanion.helpers').repo
local prompt_library = require('plugin-config.codecompanion.prompt_library')

local M = {}

-- Process helpers
local function wait_stdout(cmd, opts)
    return vim.system(cmd, opts):wait().stdout or ''
end

-- File context helpers
local function resolve_absolute_paths(files, root)
    return vim.iter(files)
        :map(function(file)
            if file == '' then
                return nil
            end

            local absolute_path = vim.fs.normalize(vim.fs.joinpath(root, file))
            local stat = vim.uv.fs_stat(absolute_path)
            if stat and stat.type == 'file' then
                return absolute_path
            end

            return nil
        end)
        :filter(function(file)
            return file ~= nil
        end)
        :totable()
end

local function resolve_diff_and_filelist_cmds(opts)
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

local function collect_changed_files(git_root, file_list_cmd)
    local result = vim.system(file_list_cmd, { text = true, cwd = git_root }):wait()
    local changed_files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

    if #changed_files == 0 or (#changed_files == 1 and changed_files[1] == '') then
        return {}, 'No relevant files found'
    end

    return resolve_absolute_paths(changed_files, git_root)
end

local function build_diff_context(opts)
    local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
    if not git_root then
        return nil
    end

    local diff_cmd, file_list_cmd, cmd_err = resolve_diff_and_filelist_cmds(opts)
    if not diff_cmd then
        vim.notify(cmd_err, vim.log.levels.ERROR)
        return nil
    end

    local absolute_files, file_err = collect_changed_files(git_root, file_list_cmd)
    if file_err then
        vim.notify(file_err, vim.log.levels.WARN)
        return nil
    end

    return {
        git_root = git_root,
        diff_cmd = diff_cmd,
        abs_files = absolute_files,
    }
end

local function find_release_commit_shas(git_root)
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

-- Describe the diff scope in prose for skill-based (ACP) slash commands
local function acp_diff_scope_phrase(opts)
    if opts and opts.base_branch then
        return string.format(
            'the changes on the current branch versus `%s` (git diff %s...HEAD)',
            opts.base_branch,
            opts.base_branch
        )
    elseif opts and opts.commit_sha then
        return string.format('commit `%s`', opts.commit_sha)
    end
    return 'the staged changes'
end

-- Slash commands
function M.conventional_commit(chat, opts)
    if chat.adapter and chat.adapter.type == 'acp' then
        local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
        if not git_root then
            return
        end
        chat_helpers.submit_user_message(
            chat,
            string.format(
                'Use your conventional-commit skill to generate a commit '
                    .. 'message for %s in the git repository at `%s`.',
                acp_diff_scope_phrase(opts),
                git_root
            )
        )
        return
    end

    local ctx = build_diff_context(opts)
    if not ctx then
        return
    end

    chat_helpers.add_context(ctx.abs_files)

    local commit_history = vim.trim(
        wait_stdout(
            { 'git', 'log', '-n', '50', '--pretty=format:%s' },
            { text = true, cwd = ctx.git_root }
        )
    )

    local diff_output = wait_stdout(ctx.diff_cmd, { text = true, cwd = ctx.git_root })

    chat_helpers.submit_user_message(
        chat,
        string.format(
            prompt_library.prompt('conventional_commits'),
            commit_history,
            diff_output
        )
    )
end

function M.code_review(chat, opts)
    if chat.adapter and chat.adapter.type == 'acp' then
        local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
        if not git_root then
            return
        end
        chat_helpers.submit_user_message(
            chat,
            string.format(
                'Use your diff-review skill to review %s in the git '
                    .. 'repository at `%s`.',
                acp_diff_scope_phrase(opts),
                git_root
            )
        )
        return
    end

    local ctx = build_diff_context(opts)
    if not ctx then
        return
    end

    chat_helpers.add_context(ctx.abs_files)

    local diff_output = wait_stdout(ctx.diff_cmd, { text = true, cwd = ctx.git_root })
    chat_helpers.submit_user_message(
        chat,
        string.format(prompt_library.prompt('code_reviewer'), diff_output)
    )
end

function M.changelog(chat, opts)
    if chat.adapter and chat.adapter.type == 'acp' then
        local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
        if not git_root then
            return
        end
        local shas = opts and opts.commit_shas
        local scope = shas
                and not vim.tbl_isempty(shas)
                and ('these commits: ' .. table.concat(shas, ', '))
            or 'the commits since the last release'
        chat_helpers.submit_user_message(
            chat,
            string.format(
                'Use your changelog skill to generate a changelog entry for %s '
                    .. 'in the git repository at `%s`.',
                scope,
                git_root
            )
        )
        return
    end

    local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
    if not git_root then
        return
    end

    local shas = opts and opts.commit_shas
    if not shas or vim.tbl_isempty(shas) then
        shas = find_release_commit_shas(git_root)
        if not shas then
            return
        end
    end

    local commit_msgs = {}
    for _, sha in ipairs(shas) do
        local msg = vim.trim(
            wait_stdout(
                { 'git', 'show', '--no-patch', '--format=%B', sha },
                { text = true, cwd = git_root }
            )
        )
        table.insert(commit_msgs, msg:gsub('\n\n+', '\n\n'))
    end

    local changelog_file = vim.fs.joinpath(git_root, 'CHANGELOG.md')
    local stat = vim.uv.fs_stat(changelog_file)
    if stat and stat.type == 'file' then
        chat_helpers.add_context({ changelog_file })
    end

    chat_helpers.submit_user_message(
        chat,
        string.format(
            prompt_library.prompt('changelog_generator'),
            table.concat(commit_msgs, '\n---\n')
        )
    )
end

return M
