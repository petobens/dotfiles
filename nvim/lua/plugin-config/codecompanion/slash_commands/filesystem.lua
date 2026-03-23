local chat_helpers = require('plugin-config.codecompanion.helpers').chat

local M = {}

-- Helpers
local function send_project_tree(chat, root)
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

local function find_git_root()
    local git_root = vim.fs.root(vim.uv.cwd(), '.git')

    if not git_root then
        vim.notify(
            'Not inside a Git repository. Could not determine the project root.',
            vim.log.levels.ERROR
        )
        return nil
    end

    return git_root
end

-- Slash commands
function M.file_path()
    vim.ui.input({ prompt = 'File path: ', completion = 'file' }, function(file)
        local stat = file and vim.uv.fs_stat(file)
        if not (stat and stat.type == 'file') then
            vim.notify(string.format('File not found: %s', file), vim.log.levels.ERROR)
            return
        end

        chat_helpers.add_context({ file })
    end)
end

function M.directory(chat)
    vim.ui.input({ prompt = 'Context dir: ', completion = 'dir' }, function(dir)
        dir = vim.fs.normalize(vim.trim(dir)):gsub('/$', '')
        vim.cmd.redraw({ bang = true })

        local stat = vim.uv.fs_stat(dir)
        if not (stat and stat.type == 'directory') then
            vim.notify('Directory not found: ' .. dir, vim.log.levels.ERROR)
            return
        end

        local context_files = {}
        for name, ftype in vim.fs.dir(dir, { depth = math.huge }) do
            if ftype == 'file' then
                table.insert(context_files, vim.fs.joinpath(dir, name))
            end
        end

        send_project_tree(chat, dir)
        chat_helpers.add_context(context_files)
    end)
end

function M.git_files(chat)
    local git_root = find_git_root()
    if not git_root then
        return
    end

    local result = vim.system({ 'git', 'ls-files' }, { text = true, cwd = git_root })
        :wait()
    local git_files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })
    local ignore_exts = { ['.png'] = true }
    local context_files = vim.iter(git_files)
        :filter(function(file)
            local ext = file:match('(%.[^%.]+)$') or ''
            return not ignore_exts[ext]
        end)
        :map(function(file)
            return vim.fs.joinpath(git_root, file)
        end)
        :totable()

    send_project_tree(chat, git_root)
    chat_helpers.add_context(context_files)
end

function M.py_files(chat)
    if vim.tbl_isempty(_G.PyVenv.active_venv) then
        vim.notify('No active Python virtual environment found.', vim.log.levels.ERROR)
        return
    end

    send_project_tree(chat, _G.PyVenv.active_venv.project_root)
    chat_helpers.add_context(_G.PyVenv.active_venv.project_files)
end

return M
