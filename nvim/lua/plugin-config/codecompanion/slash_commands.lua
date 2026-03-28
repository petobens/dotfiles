local assets = require('plugin-config.codecompanion.slash_commands.assets')
local coding = require('plugin-config.codecompanion.slash_commands.coding')
local filesystem = require('plugin-config.codecompanion.slash_commands.filesystem')
local gdocs = require('plugin-config.codecompanion.slash_commands.gdocs')
local gdrive = require('plugin-config.codecompanion.slash_commands.gdrive')
local git = require('plugin-config.codecompanion.slash_commands.git')
local gsheets = require('plugin-config.codecompanion.slash_commands.gsheets')
local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local terminal = require('plugin-config.codecompanion.slash_commands.terminal')

local M = {}

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
        -- Terminal
        ['tmux'] = {
            description = 'Add tmux pane output (window.pane) as context',
            callback = terminal.tmux,
        },
    }
end

return M
