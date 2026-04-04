local builtin = require('codecompanion.interactions.chat.tools.builtin.run_command')

-- Constants
local ALLOWED_PREFIXES = {
    -- Unix
    'cat',
    'fd',
    'file',
    'find',
    'grep',
    'head',
    'ls',
    'pwd',
    'rg',
    'sed',
    'stat',
    'tail',
    'tree',
    'wc',
    -- Lua
    'luacheck',
    'stylua',
    -- Python
    'pytest',
    -- Git
    'git branch --show-current',
    'git diff',
    'git log --oneline',
    'git show',
    'git status',
}

-- Helpers
local function scan_unquoted(cmd, on_char)
    local quote = nil
    local escaped = false

    for i = 1, #cmd do
        local char = cmd:sub(i, i)
        local next_char = cmd:sub(i + 1, i + 1)

        if escaped then
            escaped = false
        elseif char == '\\' and quote ~= "'" then
            escaped = true
        elseif quote ~= nil then
            if char == quote then
                quote = nil
            end
        elseif char == '"' or char == "'" then
            quote = char
        else
            local stop = on_char(char, next_char)
            if stop ~= nil then
                return stop
            end
        end
    end
end

local function has_forbidden_shell_chaining(cmd)
    return scan_unquoted(cmd, function(char, next_char)
        if char == '\n' or char == '\r' or char == ';' or char == '`' then
            return true
        end

        if char == '|' or char == '>' or char == '<' or char == '&' then
            return true
        end

        if char == '$' and next_char == '(' then
            return true
        end
    end) == true
end

local function matches_allowed_prefix(cmd)
    return vim.iter(ALLOWED_PREFIXES):any(function(prefix)
        return cmd == prefix or vim.startswith(cmd, prefix .. ' ')
    end)
end

local function is_whitelisted(cmd)
    local trimmed = type(cmd) == 'string' and vim.trim(cmd) or nil
    if trimmed == nil or trimmed == '' then
        return false
    end

    -- Auto-allow only commands matching the explicit prefix allowlist.
    -- Shell control operators, redirects, and pipelines remain blocked so a
    -- safe-looking command cannot smuggle arbitrary extra execution through
    -- the shell.
    if has_forbidden_shell_chaining(trimmed) then
        return false
    end

    return matches_allowed_prefix(trimmed)
end

-- Tool definition
local tool = vim.deepcopy(builtin)
tool.name = 'safe_run_command'
tool.description = 'Run approved safe shell commands, require approval otherwise'
tool.schema['function'].name = 'safe_run_command'
tool.schema['function'].description =
    'Run approved safe shell commands, require approval otherwise'
tool.opts = vim.tbl_deep_extend('force', tool.opts or {}, {
    allowed_in_yolo_mode = false,
    require_cmd_approval = true,
    require_approval_before = function(run_tool)
        local cmd = run_tool and run_tool.args and run_tool.args.cmd
        return not is_whitelisted(cmd)
    end,
})

return tool
