local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local prompt_library = require('plugin-config.codecompanion.prompt_library')
local u = require('utils')

-- Constants
local SLASH_COMMANDS = 'plugin-config.codecompanion.slash_commands.'
local assets = require(SLASH_COMMANDS .. 'assets')
local coding = require(SLASH_COMMANDS .. 'coding')
local filesystem = require(SLASH_COMMANDS .. 'filesystem')
local gdocs = require(SLASH_COMMANDS .. 'gdocs')
local gdrive = require(SLASH_COMMANDS .. 'gdrive')
local git = require(SLASH_COMMANDS .. 'git')
local gsheets = require(SLASH_COMMANDS .. 'gsheets')
local gslides = require(SLASH_COMMANDS .. 'gslides')
local skills = require(SLASH_COMMANDS .. 'skills')
local terminal = require(SLASH_COMMANDS .. 'terminal')

local M = {}

-- Helpers
local function explain_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local code = u.get_selection()
    vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
    chat_helpers.run_slash_command('explain_code', { bufnr = bufnr, code = code })
end

local function setup_qf_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>qf', function()
        chat_helpers.run_slash_command('qfix')
    end, {
        buffer = args.buf,
        desc = 'Explain quickfix diagnostics',
    })
end

local function setup_fugitive_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>cc', function()
        chat_helpers.run_slash_command('conventional_commit')
    end, {
        buffer = args.buf,
        desc = 'Generate conventional commit message',
    })

    vim.keymap.set('n', '<Leader>bc', function()
        vim.ui.input(
            { prompt = 'Base branch for commit diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    chat_helpers.run_slash_command('conventional_commit', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buffer = args.buf,
        desc = 'Conventional commit with base branch',
    })

    vim.keymap.set('n', '<Leader>cr', function()
        chat_helpers.run_slash_command('code_review')
    end, {
        buffer = args.buf,
        desc = 'Perform code review',
    })

    vim.keymap.set('n', '<Leader>br', function()
        vim.ui.input(
            { prompt = 'Base branch for diff: ', default = 'main' },
            function(branch)
                if branch and branch ~= '' then
                    chat_helpers.run_slash_command('code_review', {
                        base_branch = vim.trim(branch),
                    })
                end
            end
        )
    end, {
        buffer = args.buf,
        desc = 'Code review with base branch',
    })

    vim.keymap.set('n', '<Leader>cl', function()
        chat_helpers.run_slash_command('changelog')
    end, {
        buffer = args.buf,
        desc = 'Generate changelog since last release',
    })
end

-- Slash command definitions
local slash_commands = {
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
        callback = filesystem.file_path,
    },
    ['directory'] = {
        description = 'Insert all files in a directory',
        callback = filesystem.directory,
    },
    ['assets'] = {
        description = 'Load all assets from an assets subdirectory as context',
        callback = assets.assets,
    },
    ['git_files'] = {
        description = 'Insert all files in git repo',
        callback = filesystem.git_files,
    },
    ['py_files'] = {
        description = 'Insert all project python files',
        callback = filesystem.py_files,
    },
    -- Google Workspace
    ['gdrive_search'] = {
        description = 'Search Google Drive files',
        callback = gdrive.gdrive_search,
    },
    ['gdoc_read'] = {
        description = 'Read a Google Doc',
        callback = gdocs.gdoc_read,
    },
    ['gsheet_read'] = {
        description = 'Read a Google Sheet',
        callback = gsheets.gsheet_read,
    },
    ['gslides_read'] = {
        description = 'Read a Google Slides presentation',
        callback = gslides.gslides_read,
    },
    -- Git
    ['conventional_commit'] = {
        description = 'Generate a conventional git commit message',
        callback = git.conventional_commit,
    },
    ['code_review'] = {
        description = 'Perform a code review',
        callback = git.code_review,
    },
    ['changelog'] = {
        description = 'Generate a changelog entry from selected commits',
        callback = git.changelog,
    },
    -- Coding
    ['qfix'] = {
        description = 'Explain quickfix/loclist code diagnostics',
        callback = coding.qfix,
    },
    ['explain_code'] = {
        description = 'Explain selected code',
        callback = coding.explain_code,
    },
    -- Skills
    ['skills'] = {
        description = 'Pick a skill name from the skills directory',
        callback = skills.skills,
    },
    -- Terminal
    ['tmux'] = {
        description = 'Add tmux pane output (window.pane) as context',
        callback = terminal.tmux,
    },
}

-- Role slash commands generated from the prompt library. Unlike the built-in
-- prompt-library slash commands (which echo the prompt into the buffer and wait
-- for a manual submit), these inject the prompt invisibly and auto-submit
local function role_context_files(entry)
    local files = {}
    for _, ctx in ipairs(entry.context or {}) do
        if ctx.type == 'file' then
            vim.list_extend(files, type(ctx.path) == 'table' and ctx.path or { ctx.path })
        end
    end
    return files
end

for _, entry in pairs(prompt_library.build()) do
    local alias = entry.opts and entry.opts.alias
    if alias then
        local content = entry.prompts[1].content
        local files = role_context_files(entry)
        slash_commands[alias] = {
            description = entry.description,
            callback = function(chat)
                if #files > 0 then
                    chat_helpers.add_context(files)
                end
                chat:add_message(
                    { role = 'user', content = content },
                    { visible = false }
                )
                chat:submit({ auto_submit = true })
            end,
        }
    end
end

function M.build()
    return slash_commands
end

-- Mappings
function M.setup_mappings(group)
    -- Global
    vim.keymap.set('v', '<Leader>ec', explain_selection, {
        desc = 'Explain selected code with CodeCompanion',
    })

    vim.keymap.set('n', '<Leader>bs', skills.browse, {
        desc = 'Browse skills',
    })

    -- Autocmds
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'qf',
        desc = 'CodeCompanion quickfix mapping',
        callback = setup_qf_filetype_mappings,
    })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'fugitive',
        desc = 'CodeCompanion fugitive mappings',
        callback = setup_fugitive_filetype_mappings,
    })
end

return M
