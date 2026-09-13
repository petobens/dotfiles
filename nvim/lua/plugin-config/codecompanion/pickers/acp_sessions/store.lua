local u = require('utils')

local utils = require('codecompanion.utils')

local M = {}

local PRUNE_INTERVAL = 2 * 60 * 60
local TITLE_CACHE =
    vim.fs.joinpath(vim.fn.stdpath('data'), 'codecompanion', 'acp-session-titles.json')

-- Session file helpers
local function load_title_cache()
    local ok, data = pcall(vim.json.decode, u.read_file(TITLE_CACHE) or '')
    return (ok and type(data) == 'table') and data or {}
end

local function read_jsonl(path, max_lines)
    local out = {}
    local ok, iter = pcall(io.lines, path)
    if not ok then
        return out
    end
    for line in iter do
        local decoded_ok, decoded = pcall(vim.json.decode, line)
        if decoded_ok then
            out[#out + 1] = decoded
        end
        if #out >= max_lines then
            break
        end
    end
    return out
end

-- Read backward in chunks so finding the latest model does not scan entire sessions
local function find_last_jsonl(path, extract)
    local file = io.open(path, 'rb')
    if not file then
        return
    end

    local offset = file:seek('end') or 0
    local suffix = ''
    while offset > 0 do
        local size = math.min(offset, 64 * 1024)
        offset = offset - size
        file:seek('set', offset)
        local lines = vim.split((file:read(size) or '') .. suffix, '\n', {
            plain = true,
        })
        suffix = table.remove(lines, 1) or ''
        if offset == 0 then
            table.insert(lines, 1, suffix)
        end

        for i = #lines, 1, -1 do
            local ok, decoded = pcall(vim.json.decode, lines[i])
            local value = ok and extract(decoded)
            if value then
                file:close()
                return value
            end
        end
    end

    file:close()
end

local function saved_session_value(adapter, path, key)
    return find_last_jsonl(path, function(d)
        if adapter == 'codex' and d.type == 'turn_context' then
            return vim.tbl_get(d, 'payload', key)
        elseif adapter == 'claude_code' and d.type == 'assistant' then
            if key == 'model' then
                return vim.tbl_get(d, 'message', 'model')
            end
            local effort = type(d.perTurnEffort) == 'string' and d.perTurnEffort
                or d.effort
            return type(effort) == 'string' and effort or nil
        end
    end)
end

local function mtime(path)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.mtime.sec or 0
end

local function clean_title(title)
    return title and vim.trim(title:gsub('%s+', ' ')) or nil
end

-- Adapter scanners
-- Claude Code stores one <sessionId>.jsonl per session under a per-cwd project
-- dir. The true cwd lives in the message lines
local function scan_claude_sessions(titles)
    local entries = {}
    local files =
        vim.fn.glob(vim.fn.expand('~/.claude/projects') .. '/*/*.jsonl', true, true)
    for _, file in ipairs(files) do
        local cwd, ai_title
        for _, d in ipairs(read_jsonl(file, 500)) do
            cwd = cwd or d.cwd
            ai_title = d.aiTitle or ai_title
        end
        if cwd then
            local session_id = vim.fn.fnamemodify(file, ':t:r')
            local cached = titles['claude_code:' .. session_id]
            entries[#entries + 1] = {
                adapter = 'claude_code',
                session_id = session_id,
                cwd = cwd,
                title = clean_title((cached and cached.title) or ai_title),
                updated_at = mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
                model = saved_session_value('claude_code', file, 'model'),
                effort = saved_session_value('claude_code', file, 'effort'),
            }
        end
    end
    return entries
end

-- Codex stores date-bucketed rollout-*.jsonl files. The first `session_meta`
-- line holds the id/cwd; the label comes from the title cache
local function scan_codex_sessions(titles)
    local entries = {}
    local files = vim.fn.glob(
        vim.fn.expand('~/.codex/sessions') .. '/**/rollout-*.jsonl',
        true,
        true
    )
    for _, file in ipairs(files) do
        local meta
        for _, d in ipairs(read_jsonl(file, 50)) do
            if d.type == 'session_meta' then
                meta = d.payload
                break
            end
        end
        local is_subagent = meta and type(meta.source) == 'table' and meta.source.subagent
        if meta and meta.id and meta.cwd and not is_subagent then
            local cached = titles['codex:' .. meta.id]
            entries[#entries + 1] = {
                adapter = 'codex',
                session_id = meta.id,
                cwd = meta.cwd,
                title = clean_title(cached and cached.title),
                updated_at = mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
                model = saved_session_value('codex', file, 'model'),
                effort = saved_session_value('codex', file, 'effort'),
            }
        end
    end
    return entries
end

-- Store operations
function M.list()
    local titles = load_title_cache()
    local entries = scan_claude_sessions(titles)
    vim.list_extend(entries, scan_codex_sessions(titles))
    table.sort(entries, function(a, b)
        return (a.updated_at or 0) > (b.updated_at or 0)
    end)
    return entries
end

function M.refresh_titles(entries)
    local titles = load_title_cache()
    for _, entry in ipairs(entries) do
        local cached = titles[entry.adapter .. ':' .. entry.session_id]
        if cached and cached.title then
            entry.title = clean_title(cached.title)
        end
    end
end

-- Prune old/single-exchange sessions at most once per 2h, triggered by a browse
function M.ensure_periodic_prune()
    local stamp = vim.fs.joinpath(vim.fn.stdpath('cache'), 'ai_session_prune_stamp')
    local last = tonumber(vim.trim(u.read_file(stamp) or '')) or 0
    if os.time() - last < PRUNE_INTERVAL then
        return
    end

    local result = vim.system({ 'ai_session_prune' }, { text = true }):wait()
    if result.code == 0 then
        local n = tonumber((result.stdout or ''):match('total: deleted (%d+)')) or 0
        if n > 0 then
            utils.notify(
                string.format('Deleted %d session%s', n, n == 1 and '' or 's'),
                vim.log.levels.INFO
            )
        end
    else
        utils.notify('Session prune failed', vim.log.levels.ERROR)
    end

    local fd = io.open(stamp, 'w')
    if fd then
        fd:write(tostring(os.time()))
        fd:close()
    end
end

function M.delete(path)
    return vim.uv.fs_unlink(path)
end

return M
