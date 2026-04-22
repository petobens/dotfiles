-- luacheck:ignore 631
local M = {}

-- Constants
M.SYSTEM_ROLE = '󰮥 Helpful Assistant'
local NOTES_DIR = vim.fs.normalize('/home/pedro/git-repos/private/notes')
local MEMOS_DIR = vim.fs.joinpath(NOTES_DIR, 'mutt', 'ops', 'memos')
local PROMPT_DIR = vim.fs.normalize(
    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'ai-harness', 'prompts')
)

-- Prompt library config
local PROMPT_LIBRARY_CONFIG = {
    prompt_dir = PROMPT_DIR,
    formatting_file = 'response_formatting',
    prompt_md_files = {
        'bash_developer',
        'changelog_generator',
        'code_reviewer',
        'conventional_commits',
        'explain_code',
        'gsheets_expert',
        'helpful_assistant',
        'latex_developer',
        'lua_developer',
        'meeting_copilot',
        'pydocs',
        'python_developer',
        'quickfix',
        'slides_generator',
        'sql_developer',
        'translator_spa_eng',
        'writer_at_work',
    },
    user_prompts = {
        code_reviewer = true,
        conventional_commits = true,
        explain_code = true,
    },
}

-- Prompt library loading
local function read_prompt_file(fname)
    local path = vim.fs.joinpath(PROMPT_LIBRARY_CONFIG.prompt_dir, fname .. '.md')
    local fd = io.open(path, 'r')
    if not fd then
        vim.notify(('Prompt file not found: %s'):format(path), vim.log.levels.WARN)
        return ''
    end

    local content = fd:read('*a')
    fd:close()

    local filtered = {}
    for _, line in ipairs(vim.split(vim.trim(content or ''), '\n', { plain = true })) do
        if not line:lower():find('markdownlint') then
            table.insert(filtered, line)
        end
    end
    return table.concat(filtered, '\n'):gsub('\n$', '')
end

local function load_prompt_library()
    local stat = vim.uv.fs_stat(PROMPT_LIBRARY_CONFIG.prompt_dir)
    if not (stat and stat.type == 'directory') then
        vim.notify(
            ('Prompt directory not found: %s'):format(PROMPT_LIBRARY_CONFIG.prompt_dir),
            vim.log.levels.WARN
        )
        return {}
    end

    local prompt_library = {}
    local formatting_content = read_prompt_file(PROMPT_LIBRARY_CONFIG.formatting_file)

    for _, fname in ipairs(PROMPT_LIBRARY_CONFIG.prompt_md_files) do
        local content = read_prompt_file(fname)
        prompt_library[fname] = PROMPT_LIBRARY_CONFIG.user_prompts[fname] and content
            or (formatting_content .. '\n\n' .. content)
    end

    return prompt_library
end

-- Loaded prompt text
local PROMPT_LIBRARY = load_prompt_library()

function M.prompt(name)
    return PROMPT_LIBRARY[name]
end

function M.prompt_file(relative_path)
    return read_prompt_file(relative_path)
end

-- Shared prompt constructor
local function build_prompt(interaction, description, alias, content, extra)
    local prompt_opts = {
        alias = alias,
        ignore_system_prompt = true,
    }

    if interaction == 'chat' then
        prompt_opts.is_slash_cmd = true
    end

    return vim.tbl_deep_extend('force', {
        interaction = interaction,
        description = description,
        opts = prompt_opts,
        prompts = {
            { role = 'system', content = content },
        },
    }, extra or {})
end

-- General assistant
local function helpful_assistant_prompt()
    return build_prompt(
        'chat',
        'Act as a helpful assistant.',
        'assistant_role',
        M.prompt('helpful_assistant')
    )
end

-- Languages and expertise
local function bash_developer_prompt()
    return build_prompt(
        'chat',
        'Act as an expert Bash developer.',
        'bash_role',
        M.prompt('bash_developer')
    )
end

local function latex_developer_prompt()
    return build_prompt(
        'chat',
        'Act as an expert LaTeX developer.',
        'latex_role',
        M.prompt('latex_developer')
    )
end

local function lua_developer_prompt()
    return build_prompt(
        'chat',
        'Act as an expert Lua developer.',
        'lua_role',
        M.prompt('lua_developer'),
        {
            context = {
                {
                    type = 'file',
                    path = {
                        '/usr/share/nvim/runtime/doc/api.txt',
                        '/usr/share/nvim/runtime/doc/lua.txt',
                    },
                },
            },
        }
    )
end

local function python_developer_prompt()
    return build_prompt(
        'chat',
        'Act as an expert Python developer.',
        'python_role',
        M.prompt('python_developer')
    )
end

local function pydocs_prompt()
    return build_prompt(
        'inline',
        'Write inline Python docstrings following NumPy-style.',
        'pydocs',
        M.prompt('pydocs')
    )
end

local function sql_developer_prompt()
    return build_prompt(
        'chat',
        'Act as an expert SQL developer.',
        'sql_role',
        M.prompt('sql_developer')
    )
end

local function gsheets_expert_prompt()
    return build_prompt(
        'chat',
        'Act as a Google Sheets expert.',
        'gsheets_role',
        M.prompt('gsheets_expert')
    )
end

-- Work and communication
local function translator_prompt()
    return build_prompt(
        'chat',
        'Act as a translator from Spanish to English.',
        'translator_role',
        M.prompt('translator_spa_eng')
    )
end

local function writer_at_work_prompt()
    return build_prompt(
        'chat',
        'Write the way I write at work.',
        'writer',
        M.prompt('writer_at_work'),
        {
            context = {
                {
                    type = 'file',
                    path = {
                        vim.fs.joinpath(MEMOS_DIR, '1_tdms.md'),
                        vim.fs.joinpath(MEMOS_DIR, '2_new_structure.md'),
                        vim.fs.joinpath(MEMOS_DIR, '3_portfolios_practices.md'),
                        vim.fs.joinpath(MEMOS_DIR, '4_incentives.md'),
                    },
                },
            },
        }
    )
end

local function meeting_copilot_prompt()
    return build_prompt(
        'chat',
        'Act as a real-time stakeholder meeting copilot.',
        'meeting_role',
        string.format(
            '%s\n\nToday is: %s',
            M.prompt('meeting_copilot'),
            os.date('%d/%m/%Y')
        )
    )
end

local function slides_generator_prompt()
    return build_prompt(
        'chat',
        'Act as a slides strategy writing assistant.',
        'slides_role',
        M.prompt('slides_generator')
    )
end

-- Prompt library assembly
function M.build()
    return {
        -- General assistant
        [M.SYSTEM_ROLE] = helpful_assistant_prompt(),
        -- Languages and expertise
        [' Bash Developer'] = bash_developer_prompt(),
        [' LaTeX Developer'] = latex_developer_prompt(),
        [' Lua Developer'] = lua_developer_prompt(),
        [' Python Developer'] = python_developer_prompt(),
        [' PyDocs'] = pydocs_prompt(),
        [' SQL Developer'] = sql_developer_prompt(),
        ['󰧷 GSheets Expert'] = gsheets_expert_prompt(),
        -- Work and communication
        ['󰗊 Translator'] = translator_prompt(),
        [' Writer at Work'] = writer_at_work_prompt(),
        ['󰦑 Meeting Copilot'] = meeting_copilot_prompt(),
        ['󰐨 Slides Generator'] = slides_generator_prompt(),
    }
end

return M
