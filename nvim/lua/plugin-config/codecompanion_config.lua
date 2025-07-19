-- luacheck:ignore 631

-- TODO:
-- Plugins/Extensions:
-- VectorCode: https://github.com/Davidyz/VectorCode
-- And do something like https://github.com/olimorris/codecompanion.nvim/pull/1659
-- Try indexing the whole codecompanion repo
-- MCP Hub: https://github.com/ravitemer/mcphub.nvim
-- Possible to share a PDF file with this?
-- Sign-in/read  google doc/slides
-- https://github.com/olimorris/codecompanion.nvim/discussions/1208

-- Check how to use agents/tools (i.e @ commands, such @editor)
-- Try tavily web_search tool (and use it to crawl?)
-- Crawl with site specific search https://github.com/olimorris/codecompanion.nvim/pull/1741

-- And integrate with inline code running
-- Check terminal interaction

-- Nice to Haves:
-- Choose only some default prompts/actions
-- When using editor tool enter normal mode after exiting the chat buffer and into a diff

local adapters = require('codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local keymaps = require('codecompanion.strategies.chat.keymaps')
local telescope_action_state = require('telescope.actions.state')
local telescope_actions = require('telescope.actions')
local u = require('utils')

_G.CodeCompanionConfig = {}

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local SYSTEM_ROLE = '󰮥 Helpful Assistant'

-- Helpers
local function get_my_prompt_library()
    local formatting_file = 'response_formatting_instructions'
    local prompt_md_files = {
        'bash_developer',
        'code_reviewer',
        'conventional_commits',
        'gsheets_expert',
        'helpful_assistant',
        'latex_developer',
        'lua_developer',
        'pydocs',
        'python_developer',
        'quickfix',
        'sql_developer',
        'translator_spa_eng',
        'writer_at_work',
    }
    local user_prompts = {
        conventional_commits = true,
        code_reviewer = true,
    }
    local base_url =
        'https://raw.githubusercontent.com/petobens/llm-prompts/main/md-prompts/%s.md'
    local prompt_dir = vim.fn.expand('~/git-repos/private/llm-prompts/md-prompts/')
    local use_url = vim.fn.isdirectory(prompt_dir) ~= 1
    local prompt_library = {}

    local function read_and_filter(fname)
        local lines
        if use_url then
            lines = vim.fn.systemlist({ 'curl', '-fsSL', string.format(base_url, fname) })
        else
            lines = vim.fn.readfile(prompt_dir .. fname .. '.md')
        end

        local filtered = {}
        for _, line in ipairs(lines) do
            if not line:lower():find('markdownlint') then
                table.insert(filtered, line)
            end
        end
        return table.concat(filtered, '\n'):gsub('\n$', '')
    end

    local formatting_content = read_and_filter(formatting_file)
    for _, fname in ipairs(prompt_md_files) do
        local content = read_and_filter(fname)
        if user_prompts[fname] then
            prompt_library[fname] = content
        else
            prompt_library[fname] = formatting_content .. '\n\n' .. content
        end
    end
    return prompt_library
end

local function get_current_system_role_prompt()
    local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    local system_role = nil
    for _, entry in ipairs(chat.messages) do
        if entry.role == 'system' then
            system_role = entry.content
        end
    end
    return system_role
end

local function get_last_user_prompt()
    local chat_msgs = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf()).messages
    local last_user_prompt = nil
    for i = #chat_msgs, 1, -1 do
        if chat_msgs[i].role == 'user' then
            last_user_prompt = chat_msgs[i].content
            break
        end
    end
    return last_user_prompt
end

local function count_exchanges()
    local chat_msgs = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf()).messages
    local count = 0
    for i = 1, #chat_msgs do
        if chat_msgs[i].role == 'user' then
            count = count + 1
        end
    end
    return count
end

local function set_chat_win_title(e)
    local chatmap = {}
    local chats = codecompanion.buf_get_chat()
    for _, chat in pairs(chats) do
        chatmap[chat.chat.ui.winnr] = chat.name
    end

    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    end)

    if not ok then
        -- When renaming a chat session directly update the chat window title
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
            vim.api.nvim_win_set_config(win_id, {
                title = vim.api
                    .nvim_win_get_config(win_id).title[1][1]
                    :gsub('%b()', '(' .. e.data.title .. ')'),
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

local function try_focus_chat_float()
    -- Focus window if already open (we search for a floating window with specifix zindex)
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local conf = vim.api.nvim_win_get_config(win_id)
        if conf.focusable and conf.relative ~= '' and conf.zindex == 45 then
            vim.api.nvim_set_current_win(win_id)
            return true
        end
    end
    return false
end

local function focus_or_toggle_chat()
    if try_focus_chat_float() then
        return
    end
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd('startinsert')
    end, 1)
end

local function get_or_create_chat()
    local chat = codecompanion.last_chat()
    if not chat then
        chat = codecompanion.chat()
    end
    return chat
end

-- Slash command helpers
local function get_git_root()
    local output = vim.fn.systemlist('git rev-parse --show-toplevel')
    if vim.v.shell_error ~= 0 or not output[1] or output[1] == '' then
        return nil, 'Not inside a Git repository. Could not determine the project root.'
    end
    return vim.trim(output[1])
end

local function to_absolute_paths(files, root)
    return vim.iter(files)
        :map(function(f)
            if f == '' then
                return nil
            end
            local abs_path = vim.fs.normalize(vim.fs.joinpath(root, f))
            if vim.fn.filereadable(abs_path) == 1 then
                return abs_path
            end
            return nil
        end)
        :filter(function(f)
            return f ~= nil
        end)
        :totable()
end

local function send_project_tree(chat, root)
    local tree = vim.fn.system({ 'tree', '-a', '-L', '2', '--noreport', root })
    chat:add_message({
        role = 'user',
        content = string.format('The project structure is given by:\n%s', tree),
    })
end

local function get_loclists_or_qf_entries()
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

    local seen, entries, references = {}, {}, {}
    for _, item in ipairs(diagnostics) do
        local filename = vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ':p')
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
            if filename ~= '' and not vim.tbl_contains(references, filename) then
                table.insert(references, filename)
            end
        end
    end
    return table.concat(entries, '\n'), references
end

-- Globals
function _G.CodeCompanionConfig.add_references(files)
    local chat = get_or_create_chat()
    for _, file in ipairs(files) do
        local content = table.concat(vim.fn.readfile(file), '\n')
        chat:add_reference({
            role = 'user',
            content = string.format('Here is the content of %s:%s', file, content),
        }, 'file', string.format(
            '<file>%s</file>',
            vim.fn.fnamemodify(file, ':t')
        ))
    end
    focus_or_toggle_chat()
end

function _G.CodeCompanionConfig.run_slash_command(name, opts)
    opts = opts or {}
    local chat = get_or_create_chat()
    local cmd = config.strategies.chat.slash_commands[name]
    if cmd and type(cmd.callback) == 'function' then
        cmd.callback(chat, opts)
        focus_or_toggle_chat()
    else
        vim.notify('Slash command not found: ' .. tostring(name), vim.log.levels.ERROR)
    end
end

-- Setup
local PROMPT_LIBRARY = get_my_prompt_library()
codecompanion.setup({
    adapters = {
        opts = {
            show_defaults = false,
            show_model_choices = false,
        },
        openai_gpt_41 = function()
            return adapters.extend('openai', {
                name = 'openai_gpt_41',
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'gpt-4.1' },
                    max_tokens = { default = 2048 },
                    temperature = { default = 0.2 },
                    top_p = { default = 0.1 },
                },
            })
        end,
        openai_o4_mini = function()
            return adapters.extend('openai', {
                name = 'openai_o4_mini',
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'o4-mini' },
                },
            })
        end,
        gemini_flash_25 = function()
            return adapters.extend('gemini', {
                env = { api_key = GEMINI_API_KEY },
                name = 'gemini_flash_25',
                schema = {
                    model = { default = 'gemini-2.5-flash' },
                    max_tokens = { default = 2048 },
                    reasoning_effort = { default = 'none' },
                },
            })
        end,
        gemini_pro_25 = function()
            return adapters.extend('gemini', {
                name = 'gemini_pro_25',
                env = { api_key = GEMINI_API_KEY },
                schema = {
                    model = { default = 'gemini-2.5-pro' },
                },
            })
        end,
        ollama_qwen3_2b = function()
            return adapters.extend('ollama', {
                name = 'ollama_qwen3_2b',
                schema = {
                    model = {
                        default = 'qwen3:1.7b',
                    },
                },
            })
        end,
    },
    display = {
        chat = {
            intro_message = '',
            icons = {
                buffer_pin = ' ',
                buffer_watch = ' ',
            },
            window = {
                layout = 'float',
                border = 'rounded',
                height = vim.o.lines - 5, -- (tabline, statuline and cmdline height + row)
                width = 0.45,
                relative = 'editor',
                col = vim.o.columns, -- right position
                row = 1,
                opts = {},
            },
            debug_window = {
                width = math.floor(vim.o.columns * 0.535),
                height = vim.o.lines - 4,
            },
        },
        action_palette = {
            prompt = '> ',
            opts = {
                show_default_actions = true,
                show_default_prompt_library = false,
            },
        },
        diff = { layout = 'vertical' },
    },
    strategies = {
        chat = {
            adapter = 'openai_gpt_41',
            roles = {
                user = 'Me',
                llm = function(adapter)
                    local current_system_role_prompt = get_current_system_role_prompt()
                    local system_role = SYSTEM_ROLE

                    for name, prompt in pairs(config.prompt_library) do
                        local prompt_content = prompt.prompts[1]
                            and prompt.prompts[1].content
                        if
                            type(prompt_content) == 'string'
                            and prompt_content == current_system_role_prompt
                        then
                            system_role = name
                            break
                        end
                    end
                    return string.format(
                        '%s (%s) | %s | %d Exchanges',
                        adapter.formatted_name,
                        adapter.schema.model.default,
                        system_role,
                        count_exchanges()
                    )
                end,
            },
            opts = {
                prompt_decorator = function(message, adapter, _)
                    if adapter.model.name == 'qwen3:1.7b' then
                        return string.format([[/no_think %s]], message)
                    else
                        return message
                    end
                end,
                goto_file_action = function(fname)
                    vim.cmd('wincmd h')
                    vim.cmd('e ' .. fname)
                end,
            },
            keymaps = {
                create_chat = {
                    modes = { n = '<A-c>', i = '<A-c>' },
                    description = 'Create new chat',
                    callback = function()
                        vim.cmd('CodeCompanionChat')
                    end,
                },
                close = { modes = { n = '<A-x>', i = '<A-x>' } }, -- delete chat
                hide_chats = {
                    modes = { n = '<C-c>', i = '<C-c>' },
                    description = 'Hide chats',
                    callback = function()
                        codecompanion.toggle()
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                next_chat = { modes = { n = '<A-n>', i = '<A-n>' } },
                previous_header = { modes = { n = '<C-[>', i = '<C-[>' } },
                next_header = { modes = { n = '<C-]>', i = '<C-]>' } },
                send = { modes = { n = '<C-o>', i = '<C-o>' } },
                stop = { modes = { n = '<C-x>', i = '<C-x>' } },
                clear = { modes = { n = '<A-w>', i = '<A-w>' } },
                yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
                fold_code = { modes = { n = 'zc' } },
                goto_file_under_cursor = { modes = { n = 'gf', x = 'gf' } },
                options = {
                    modes = { n = '<A-h>', i = '<A-h>' },
                    callback = function()
                        keymaps.options.callback()
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                change_adapter = { modes = { n = '<A-m>', i = '<A-m>' } },
                debug = {
                    modes = { n = '<A-d>', i = '<A-d>' },
                    callback = function(chat)
                        keymaps.debug.callback(chat)
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                pin = { modes = { n = '<Leader>rp' } },
                watch = { modes = { n = '<Leader>rw' } },
                system_prompt = { modes = { n = '<Leader>ts' } },
                action_palette = {
                    modes = { n = '<A-a>', i = '<A-a>' },
                    description = 'Action palette',
                    callback = function()
                        vim.cmd('CodeCompanionActions')
                    end,
                },
            },
            slash_commands = {
                -- Default
                ['help'] = { opts = { max_lines = 10000 } },
                ['image'] = {
                    opts = {
                        dirs = { '~/Pictures/Screenshots/' },
                    },
                },
                -- Custom
                ['file_path'] = {
                    description = 'Insert a filepath',
                    keymaps = { modes = { n = '<C-f>', i = '<C-f>' } },
                    callback = function()
                        vim.ui.input(
                            { prompt = 'File path: ', completion = 'file' },
                            function(file)
                                if not file or vim.fn.filereadable(file) == 0 then
                                    vim.notify(
                                        'File not found: ' .. tostring(file),
                                        vim.log.levels.ERROR
                                    )
                                    return
                                else
                                    _G.CodeCompanionConfig.add_references({ file })
                                end
                            end
                        )
                    end,
                },
                ['directory'] = {
                    description = 'Insert all files in a directory',
                    callback = function(chat)
                        vim.ui.input(
                            { prompt = 'Context dir: ', completion = 'dir' },
                            function(dir)
                                dir = vim.fn
                                    .trim(vim.fn.fnamemodify(dir, ':ph'))
                                    :gsub('/$', '')
                                vim.cmd('redraw!')
                                if vim.fn.isdirectory(dir) == 0 then
                                    vim.notify(
                                        'Directory not found: ' .. dir,
                                        vim.log.levels.ERROR
                                    )
                                    return
                                end
                                local glob_result = vim.fn.glob(dir .. '/*', false, true)
                                local files = {}
                                for _, file in ipairs(glob_result) do
                                    if vim.fn.isdirectory(file) == 0 then
                                        table.insert(files, file)
                                    end
                                end
                                send_project_tree(chat, dir)
                                _G.CodeCompanionConfig.add_references(files)
                            end
                        )
                    end,
                },
                ['git_files'] = {
                    description = 'Insert all files in git repo',
                    callback = function(chat)
                        local git_root, err = get_git_root()
                        if not git_root then
                            vim.notify(err, vim.log.levels.ERROR)
                            return
                        end
                        local git_files =
                            vim.fn.systemlist('git ls-files --full-name ' .. git_root)

                        local ignore_exts = { ['.png'] = true }
                        local function has_ignored_ext(filename)
                            local ext = filename:match('(%.[^%.]+)$') or ''
                            return ignore_exts[ext] or false
                        end
                        local files = vim.tbl_map(
                            function(f)
                                return git_root .. '/' .. f
                            end,
                            vim.tbl_filter(function(f)
                                return not has_ignored_ext(f)
                            end, git_files)
                        )

                        send_project_tree(chat, git_root)
                        _G.CodeCompanionConfig.add_references(files)
                    end,
                },
                ['py_files'] = {
                    description = 'Insert all project python files',
                    callback = function(chat)
                        if vim.tbl_isempty(_G.PyVenv.active_venv) then
                            vim.notify(
                                'No active Python virtual environment found.',
                                vim.log.levels.ERROR
                            )
                            return
                        end
                        send_project_tree(chat, _G.PyVenv.active_venv.project_root)
                        _G.CodeCompanionConfig.add_references(
                            _G.PyVenv.active_venv.project_files
                        )
                    end,
                },
                ['conventional_commit'] = {
                    description = 'Generate a conventional git commit message',
                    callback = function(chat)
                        local git_root, err = get_git_root()
                        if not git_root then
                            vim.notify(err, vim.log.levels.ERROR)
                            return
                        end

                        local staged = vim.fn.systemlist('git diff --cached --name-only')
                        if #staged == 0 or (#staged == 1 and staged[1] == '') then
                            vim.notify('No staged changes found', vim.log.levels.WARN)
                            return
                        end
                        local abs_files = to_absolute_paths(staged, git_root)
                        _G.CodeCompanionConfig.add_references(abs_files)

                        local commit_history = table.concat(
                            vim.fn.systemlist('git log -n 50 --pretty=format:%s'),
                            '\n'
                        )

                        chat:add_buf_message({
                            role = 'user',
                            content = string.format(
                                PROMPT_LIBRARY['conventional_commits'],
                                commit_history,
                                vim.fn.system('git diff --no-ext-diff --staged')
                            ),
                        })
                        chat:submit()
                    end,
                },
                ['code_review'] = {
                    description = 'Perform a code review',
                    callback = function(chat, opts)
                        local git_root, err = get_git_root()
                        if not git_root then
                            vim.notify(err, vim.log.levels.ERROR)
                            return
                        end

                        local diff_cmd = 'git diff --no-ext-diff '
                        local file_list_cmd = 'git diff --name-only '
                        if opts and opts.base_branch then
                            local base = opts.base_branch
                            vim.fn.systemlist('git rev-parse --verify ' .. base)
                            if vim.v.shell_error ~= 0 then
                                vim.notify(
                                    'Base branch not found: ' .. base,
                                    vim.log.levels.ERROR
                                )
                                return
                            end
                            diff_cmd = diff_cmd .. base .. '...HEAD'
                            file_list_cmd = file_list_cmd .. base .. '...HEAD'
                        elseif opts and opts.commit_sha then
                            local sha = opts.commit_sha
                            diff_cmd = diff_cmd .. sha .. '^!'
                            file_list_cmd = file_list_cmd .. sha .. '^!'
                        else
                            diff_cmd = diff_cmd .. '--staged'
                            file_list_cmd = file_list_cmd .. '--cached'
                        end

                        local file_list = vim.fn.systemlist(file_list_cmd)
                        if
                            #file_list == 0 or (#file_list == 1 and file_list[1] == '')
                        then
                            vim.notify('No relevant files found', vim.log.levels.WARN)
                            return
                        end
                        local abs_files = to_absolute_paths(file_list, git_root)
                        _G.CodeCompanionConfig.add_references(abs_files)

                        chat:add_buf_message({
                            role = 'user',
                            content = string.format(
                                PROMPT_LIBRARY['code_reviewer'],
                                vim.fn.system(diff_cmd)
                            ),
                        })
                        chat:submit()
                    end,
                },
                ['qfix'] = {
                    description = 'Explain quickfix/loclist code diagnostics',
                    callback = function(chat)
                        local entries, references = get_loclists_or_qf_entries()
                        if entries == '' then
                            vim.notify(
                                'No diagnostics found in quickfix or location lists.',
                                vim.log.levels.ERROR
                            )
                            return
                        end
                        _G.CodeCompanionConfig.add_references(references)
                        chat:add_buf_message({
                            role = 'user',
                            content = string.format(PROMPT_LIBRARY['quickfix'], entries),
                        })
                        chat:submit()
                    end,
                },
            },
            variables = {
                ['buffer'] = {
                    opts = {
                        default_params = 'watch',
                    },
                },
            },
        },
        inline = {
            adapter = 'openai_gpt_41',
            keymaps = {
                accept_change = { modes = { n = 'dp' } },
                reject_change = { modes = { n = 'de' } },
            },
        },
    },
    opts = {
        system_prompt = function()
            return PROMPT_LIBRARY['helpful_assistant']
        end,
    },
    prompt_library = {
        [SYSTEM_ROLE] = {
            strategy = 'chat',
            description = 'Act as a helpful assistant.',
            opts = {
                short_name = 'assistant_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['helpful_assistant'] },
                { role = 'user', content = '' },
            },
        },
        [' Bash Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Bash developer.',
            opts = {
                short_name = 'bash_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['bash_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' LaTeX Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert LaTeX developer.',
            opts = {
                short_name = 'latex_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['latex_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' Lua Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Lua developer.',
            opts = {
                short_name = 'lua_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            references = {
                {
                    type = 'file',
                    path = {
                        '/usr/share/nvim/runtime/doc/api.txt',
                        '/usr/share/nvim/runtime/doc/lua.txt',
                    },
                },
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['lua_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' Python Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Python developer.',
            opts = {
                short_name = 'python_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['python_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' PyDocs'] = {
            strategy = 'inline',
            description = 'Write inline Python docstrings following NumPy-style.',
            opts = {
                short_name = 'pydocs',
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['pydocs'] },
                { role = 'user', content = '' },
            },
        },
        [' SQL Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert SQL developer.',
            opts = {
                short_name = 'Sql_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['sql_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' Writer at Work'] = {
            strategy = 'chat',
            description = 'Write the way I write at work.',
            opts = {
                short_name = 'writer',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            references = {
                {
                    type = 'file',
                    path = {
                        '/home/pedro/git-repos/private/notes/mutt/ops/memos/1_tdms.md',
                        '/home/pedro/git-repos/private/notes/mutt/ops/memos/2_new_structure.md',
                    },
                },
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['writer_at_work'] },
                { role = 'user', content = '' },
            },
        },
        ['󰗊 Translator'] = {
            strategy = 'chat',
            description = 'Act as a translator from Spanish to English.',
            opts = {
                short_name = 'translator_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['translator_spa_eng'] },
                { role = 'user', content = '' },
            },
        },
        ['󰧷 GSheets Expert'] = {
            strategy = 'chat',
            description = 'Act as a Google Sheets expert.',
            opts = {
                short_name = 'gsheets_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['gsheets_expert'] },
                { role = 'user', content = '' },
            },
        },
    },
    extensions = {
        history = {
            enabled = true,
            opts = {
                auto_generate_title = u.is_online(),
                title_generation_opts = {
                    adapter = 'openai_gpt_41',
                    model = 'gpt-4.1',
                    refresh_every_n_prompts = 3,
                    max_refreshes = 10,
                },
                auto_save = true,
                expiration_days = 30,
                keymap = { n = '<A-s>', i = '<A-s>' },
                picker_keymaps = {
                    rename = { n = 'r', i = '<A-r>' },
                    delete = { n = 'd', i = '<A-d>' },
                },
                save_chat_keymap = { n = '<nop>', i = '<nop>' },
            },
        },
    },
})

-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register('markdown', 'codecompanion')

-- Override the default icon for codecompanion filetype
local devicons = require('nvim-web-devicons')
devicons.set_icon({
    codecompanion = { icon = ' ' },
})
devicons.set_icon_by_filetype({ codecompanion = 'codecompanion' })

-- Set chat window title
vim.api.nvim_create_autocmd('User', {
    pattern = {
        'CodeCompanionChatCreated',
        'CodeCompanionChatOpened',
        'CodeCompanionHistoryTitleSet',
    },
    callback = function(e)
        vim.defer_fn(function()
            set_chat_win_title(e)
        end, 1)
    end,
})

-- Show a spinner working indicator when a request is being made
local ns_id = vim.api.nvim_create_namespace('codecompanion_spinner')
local spinner_states = { '', '', '' }
local spinner_bufnr, spinner_line, spinner_timer, spinner_index = nil, nil, nil, 1

local function clear_spinner()
    if spinner_bufnr and vim.api.nvim_buf_is_valid(spinner_bufnr) then
        vim.api.nvim_buf_clear_namespace(spinner_bufnr, ns_id, 0, -1)
    end
    spinner_bufnr, spinner_line, spinner_index = nil, nil, 1
    if spinner_timer then
        spinner_timer:stop()
        spinner_timer:close()
        spinner_timer = nil
    end
end

local function update_spinner()
    if spinner_bufnr and spinner_line and vim.api.nvim_buf_is_valid(spinner_bufnr) then
        vim.api.nvim_buf_clear_namespace(
            spinner_bufnr,
            ns_id,
            spinner_line,
            spinner_line + 1
        )
        vim.api.nvim_buf_set_virtual_text(
            spinner_bufnr,
            ns_id,
            spinner_line,
            { { ' Working ' .. spinner_states[spinner_index], 'Comment' } },
            {}
        )
        spinner_index = spinner_index % #spinner_states + 1
    end
end

vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestStarted',
    callback = function()
        if vim.bo.filetype == 'codecompanion' then
            vim.cmd('stopinsert')
        end
        clear_spinner()
        spinner_bufnr = vim.api.nvim_get_current_buf()
        spinner_line = vim.api.nvim_win_get_cursor(0)[1] - 1
        spinner_timer = vim.uv.new_timer()
        spinner_timer:start(0, 250, vim.schedule_wrap(update_spinner))
    end,
})

vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestStreaming',
    callback = function()
        vim.defer_fn(clear_spinner, 50)
    end,
})

vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestFinished',
    callback = function()
        vim.defer_fn(function()
            clear_spinner()
            if vim.bo.filetype == 'codecompanion' then
                vim.cmd('startinsert')
            end
        end, 50)
    end,
})

-- Ensure diffs start in normal mode and follow correct window order
vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionDiffAttached',
    callback = function()
        vim.defer_fn(function()
            vim.cmd('stopinsert')
            vim.cmd('wincmd x | wincmd p')
        end, 1)
    end,
})

-- Chat mappings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true }),
    pattern = { 'codecompanion' },
    callback = function(e)
        -- Mappings
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-p>', function()
            local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
            vim.print(string.format('Model Params:\n%s', vim.inspect(chat.settings)))
        end, { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-r>', function()
            local system_role = get_current_system_role_prompt()
            if system_role then
                vim.print(system_role)
            end
        end, { buffer = e.buf })
        vim.keymap.set({ 'i' }, '<C-p>', function()
            vim.cmd.stopinsert()
            local last_prompt = vim.split(get_last_user_prompt(), '\n', { plain = true })
            vim.api.nvim_put(last_prompt, 'c', true, true)
            vim.defer_fn(function()
                vim.cmd('startinsert!')
            end, 1)
        end, { buffer = e.buf })
    end,
})

-- Filetype mappings
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'qf' },
    callback = function(args)
        vim.keymap.set('n', '<leader>qf', function()
            _G.CodeCompanionConfig.run_slash_command('qfix')
        end, { buffer = args.buf })
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'fugitive' },
    callback = function(args)
        vim.keymap.set('n', '<Leader>cc', function()
            _G.CodeCompanionConfig.run_slash_command('conventional_commit')
        end, { buffer = args.buf })
        vim.keymap.set('n', '<Leader>cr', function()
            _G.CodeCompanionConfig.run_slash_command('code_review')
        end, { buffer = args.buf })
        vim.keymap.set('n', '<Leader>pr', function()
            vim.ui.input(
                { prompt = 'Base branch for diff: ', default = 'main' },
                function(branch)
                    if branch and branch ~= '' then
                        _G.CodeCompanionConfig.run_slash_command(
                            'code_review',
                            { base_branch = vim.trim(branch) }
                        )
                    end
                end
            )
        end, { buffer = args.buf })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>cg', focus_or_toggle_chat)
vim.keymap.set({ 'n', 'v' }, '<Leader>cr', ':CodeCompanion ', { silent = false })
vim.keymap.set({ 'n', 'v' }, '<Leader>ca', '<Cmd>CodeCompanionActions<CR>')
vim.keymap.set('n', '<Leader>cb', '<Cmd>CodeCompanionHistory<CR>')
vim.keymap.set({ 'n' }, '<Leader>ce', function()
    codecompanion.actions()
    vim.defer_fn(function()
        local picker =
            telescope_action_state.get_current_picker(vim.api.nvim_get_current_buf())
        picker:move_selection(-1)
        telescope_actions.select_default(picker)
    end, 150)
end)
vim.keymap.set({ 'v' }, '<Leader>cp', function()
    codecompanion.add()
    if vim.bo.filetype ~= 'codecompanion' then
        try_focus_chat_float()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
            'n',
            false
        )
    end
end)
vim.keymap.set('v', '<Leader>ec', function()
    codecompanion.prompt('explain')
end, { noremap = true, silent = true })
