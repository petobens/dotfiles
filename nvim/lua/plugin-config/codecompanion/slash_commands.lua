local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local prompt_library = require('plugin-config.codecompanion.prompt_library')
local u = require('utils')

-- Constants
local SLASH_COMMANDS = 'plugin-config.codecompanion.slash_commands.'
local clone = require(SLASH_COMMANDS .. 'clone')
local coding = require(SLASH_COMMANDS .. 'coding')
local git = require(SLASH_COMMANDS .. 'git')
local session = require(SLASH_COMMANDS .. 'session')
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
        buf = args.buf,
        desc = '[Q]uick[f]ix diagnostics with CodeCompanion',
    })
end

local function setup_fugitive_filetype_mappings(args)
    vim.keymap.set('n', '<Leader>cc', function()
        chat_helpers.run_slash_command('conventional_commit')
    end, {
        buf = args.buf,
        desc = '[C]onventional [c]ommit message: generate',
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
        buf = args.buf,
        desc = '[B]ase-branch [c]onventional commit message',
    })

    vim.keymap.set('n', '<Leader>cr', function()
        chat_helpers.run_slash_command('code_review')
    end, {
        buf = args.buf,
        desc = '[C]ode [r]eview: perform',
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
        buf = args.buf,
        desc = '[B]ase-branch code [r]eview',
    })

    vim.keymap.set('n', '<Leader>cl', function()
        chat_helpers.run_slash_command('changelog')
    end, {
        buf = args.buf,
        desc = '[C]hange[l]og since last release: generate',
    })
end

local function skill_input(skill, prompt, request)
    return function(chat)
        vim.ui.input({ prompt = prompt }, function(input)
            input = vim.trim(input or '')
            if input == '' then
                return
            end
            chat_helpers.request_skill(
                chat,
                skill,
                string.format('%s `%s`', request, input)
            )
            vim.schedule(vim.cmd.stopinsert)
        end)
    end
end

-- Slash command definitions
local slash_commands = {
    -- Built-in
    ['acp_session_options'] = {
        keymaps = {
            modes = { n = '<A-o>', i = '<A-o>' },
        },
    },
    ['help'] = { opts = { max_lines = 10000 } },
    ['clone'] = {
        description = 'Clone this chat into a new session',
        callback = clone.clone_chat,
    },
    ['image'] = {
        description = 'Insert a screenshot',
        callback = function()
            require('telescope.builtin').find_files({
                cwd = vim.fs.joinpath(vim.env.HOME, 'Pictures', 'Screenshots'),
            })
        end,
    },
    -- ACP sessions
    ['find_session'] = {
        description = 'Find an ACP session by conversation topic',
        callback = session.find_session,
    },
    -- Google Workspace
    ['gdrive_search'] = {
        description = 'Search Google Drive files',
        callback = skill_input(
            'gdrive',
            'Google Drive search: ',
            'search Google Drive for files matching'
        ),
    },
    ['gdoc_read'] = {
        description = 'Read a Google Doc',
        callback = skill_input('gdocs', 'Google Doc URL or ID: ', 'read the Google Doc'),
    },
    ['gsheet_read'] = {
        description = 'Read a Google Sheet',
        callback = skill_input(
            'gsheets',
            'Google Sheet URL or ID: ',
            'read the Google Sheet'
        ),
    },
    ['gslides_read'] = {
        description = 'Read a Google Slides presentation',
        callback = skill_input(
            'gslides',
            'Google Slides URL or ID: ',
            'read the Google Slides presentation'
        ),
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
        description = 'Fix quickfix/loclist code diagnostics',
        callback = coding.qfix,
    },
    ['explain_code'] = {
        description = 'Explain visually selected code',
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
        desc = '[E]xplain [c]ode selection with CodeCompanion',
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
