local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local repo_helpers = require('plugin-config.codecompanion.helpers').repo

local M = {}

local function diff_scope(opts)
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

local function request_repo_skill(chat, skill, request)
    local git_root = repo_helpers.git_root_or_notify(vim.uv.cwd())
    if not git_root then
        return
    end
    chat_helpers.request_skill(
        chat,
        skill,
        string.format('%s in the git repository at `%s`', request, git_root)
    )
end

-- Slash commands
function M.conventional_commit(chat, opts)
    request_repo_skill(
        chat,
        'conventional-commit',
        'generate a commit message for ' .. diff_scope(opts)
    )
end

function M.code_review(chat, opts)
    request_repo_skill(chat, 'diff-review', 'review ' .. diff_scope(opts))
end

function M.changelog(chat, opts)
    local shas = opts and opts.commit_shas
    local scope = shas
            and not vim.tbl_isempty(shas)
            and ('these commits: ' .. table.concat(shas, ', '))
        or 'the commits since the last release'
    request_repo_skill(chat, 'changelog', 'generate a changelog entry for ' .. scope)
end

return M
