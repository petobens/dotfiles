local u = require('utils')

local utils = require('codecompanion.utils')

local M = {}

local PRUNE_INTERVAL = 2 * 60 * 60
local TITLE_CACHE =
    vim.fs.joinpath(vim.fn.stdpath('data'), 'codecompanion', 'acp-session-titles.json')
local session_settings = {}
local pruning = false
local on_pruned

-- Helpers
local function mtime(path)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.mtime.sec or 0
end

local function clean_title(title)
    return title and vim.trim(title:gsub('%s+', ' ')) or nil
end

-- Session file helpers
local function load_title_cache()
    local ok, data = pcall(vim.json.decode, u.read_file(TITLE_CACHE) or '')
    return (ok and type(data) == 'table') and data or {}
end

local function read_jsonl(path, max_lines, visit)
    local file = io.open(path, 'r')
    if not file then
        return
    end
    local count = 0
    for line in file:lines() do
        local decoded_ok, decoded = pcall(vim.json.decode, line)
        if decoded_ok then
            count = count + 1
            if visit(decoded) then
                break
            end
        end
        if count >= max_lines then
            break
        end
    end
    file:close()
end

-- Read backward in chunks so finding the latest model does not scan entire sessions
local function find_last_jsonl(path, kind, extract)
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
            local ok, decoded
            if lines[i]:find('"type"%s*:%s*"' .. kind .. '"') then
                ok, decoded = pcall(vim.json.decode, lines[i])
            end
            local value = ok and extract(decoded)
            if value then
                file:close()
                return value
            end
        end
    end

    file:close()
end

local function saved_session_values(adapter, path)
    local stat = vim.uv.fs_stat(path)
    if not stat then
        return {}
    end
    local cached = session_settings[path]
    if
        cached
        and cached.size == stat.size
        and cached.mtime.sec == stat.mtime.sec
        and cached.mtime.nsec == stat.mtime.nsec
    then
        return cached.values
    end

    local values = {}
    local kind = adapter == 'codex' and 'turn_context' or 'assistant'
    find_last_jsonl(path, kind, function(d)
        if adapter == 'codex' and d.type == 'turn_context' then
            values.model = values.model or vim.tbl_get(d, 'payload', 'model')
            values.effort = values.effort or vim.tbl_get(d, 'payload', 'effort')
        elseif adapter == 'claude_code' and d.type == 'assistant' then
            values.model = values.model or vim.tbl_get(d, 'message', 'model')
            local effort = type(d.perTurnEffort) == 'string' and d.perTurnEffort
                or d.effort
            values.effort = values.effort or type(effort) == 'string' and effort or nil
        end
        return values.model and values.effort
    end)
    session_settings[path] = { size = stat.size, mtime = stat.mtime, values = values }
    return values
end

-- Adapter scanners
-- Claude Code stores one <sessionId>.jsonl per session under a per-cwd project
-- dir. The true cwd lives in the message lines
local function scan_claude_sessions(titles)
    local entries = {}
    local files =
        vim.fn.glob(vim.fn.expand('~/.claude/projects') .. '/*/*.jsonl', true, true)
    for _, file in ipairs(files) do
        local session_id = vim.fn.fnamemodify(file, ':t:r')
        local cached = titles['claude_code:' .. session_id]
        local cwd, ai_title
        read_jsonl(file, 500, function(d)
            cwd = cwd or d.cwd
            ai_title = d.aiTitle or ai_title
            return cwd and cached and cached.title
        end)
        if cwd then
            local settings = saved_session_values('claude_code', file)
            entries[#entries + 1] = {
                adapter = 'claude_code',
                session_id = session_id,
                cwd = cwd,
                title = clean_title((cached and cached.title) or ai_title),
                updated_at = mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
                model = settings.model,
                effort = settings.effort,
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
        read_jsonl(file, 50, function(d)
            if d.type == 'session_meta' then
                meta = d.payload
                return true
            end
        end)
        local is_subagent = meta and type(meta.source) == 'table' and meta.source.subagent
        if meta and meta.id and meta.cwd and not is_subagent then
            local cached = titles['codex:' .. meta.id]
            local settings = saved_session_values('codex', file)
            entries[#entries + 1] = {
                adapter = 'codex',
                session_id = meta.id,
                cwd = meta.cwd,
                title = clean_title(cached and cached.title),
                updated_at = mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
                model = settings.model,
                effort = settings.effort,
            }
        end
    end
    return entries
end

-- Store operations
function M.after_prune(callback)
    if pruning then
        -- Repeated reopen requests should produce only one picker
        on_pruned = callback
    else
        callback()
    end
end

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
    local changed = false
    for _, entry in ipairs(entries) do
        local cached = titles[entry.adapter .. ':' .. entry.session_id]
        if cached and cached.title then
            local title = clean_title(cached.title)
            if title ~= entry.title then
                entry.title = title
                changed = true
            end
        end
    end
    return changed
end

-- Prune old/single-exchange sessions in the background after closing the picker
function M.ensure_periodic_prune()
    local stamp = vim.fs.joinpath(vim.fn.stdpath('cache'), 'ai_session_prune_stamp')
    local last = tonumber(vim.trim(u.read_file(stamp) or '')) or 0
    if pruning or os.time() - last < PRUNE_INTERVAL then
        return
    end

    pruning = true
    local ok, err = pcall(
        vim.system,
        { 'ai_session_prune' },
        { text = true },
        vim.schedule_wrap(function(result)
            pruning = false
            if result.code == 0 then
                local n = tonumber((result.stdout or ''):match('total: deleted (%d+)'))
                    or 0
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
            if on_pruned then
                local callback = on_pruned
                on_pruned = nil
                callback()
            end
        end)
    )
    if not ok then
        pruning = false
        utils.notify('Session prune failed: ' .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.delete(path)
    return vim.uv.fs_unlink(path)
end

return M
