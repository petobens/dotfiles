local helpers = require('plugin-config.codecompanion.helpers')
local utils = require('codecompanion.utils')
local state_helpers = helpers.state

local M = {}

local CLOCK = '\239\128\151' -- nf-fa-clock_o (U+F017)
local TITLE_WIDTH = 80

-- Rough token estimate (~4 chars/token) from the session file size
local function fmt_weight(size)
    local k = (size or 0) / 4 / 1000
    return k >= 1 and string.format('~%.1fk', k) or string.format('~%d', (size or 0) / 4)
end

-- Read up to `max_lines` newline-delimited JSON objects from a file
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

local function mtime(path)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.mtime.sec or 0
end

local function clean_title(title)
    return title and vim.trim(title:gsub('%s+', ' ')) or nil
end

local function trim_chars(text, width)
    text = vim.trim((text or ''):gsub('%s+', ' '))
    if vim.fn.strdisplaywidth(text) <= width then
        return text
    end

    local suffix = '...'
    local limit = width - vim.fn.strdisplaywidth(suffix)
    local out = {}
    local current_width = 0

    for i = 0, vim.fn.strchars(text) - 1 do
        local char = vim.fn.strcharpart(text, i, 1)
        local char_width = vim.fn.strdisplaywidth(char)
        if current_width + char_width > limit then
            break
        end
        out[#out + 1] = char
        current_width = current_width + char_width
    end

    return table.concat(out) .. suffix
end

local function pad_right(text, width)
    return text .. string.rep(' ', math.max(width - vim.fn.strdisplaywidth(text), 0))
end

local function prepare_display(entries)
    local title_width, weight_width, time_width = 0, 0, 0

    for _, e in ipairs(entries) do
        e.display_icon = state_helpers.provider_icon(e.adapter)
        e.display_title = trim_chars(e.title or e.session_id, TITLE_WIDTH)
        e.display_weight = fmt_weight(e.size)
        e.display_time = e.updated_at and utils.make_relative(e.updated_at) or '?'
        e.display_cwd = e.cwd and vim.fn.fnamemodify(e.cwd, ':~') or ''

        title_width = math.max(title_width, vim.fn.strdisplaywidth(e.display_title))
        weight_width = math.max(weight_width, vim.fn.strdisplaywidth(e.display_weight))
        time_width = math.max(time_width, vim.fn.strdisplaywidth(e.display_time))
    end

    for _, e in ipairs(entries) do
        e.display_title_width = title_width
        e.display_weight_width = weight_width
        e.display_time_width = time_width
    end
end

local function delete_session(path)
    return vim.uv.fs_unlink(path)
end

-- Context that CodeCompanion/agents inject ahead of the real prompt (shared
-- rule files, environment blocks) makes for useless, identical labels
local function is_injected(text)
    return text:match('^Sharing `') ~= nil
        or text:match('^# AGENTS%.md') ~= nil
        or text:match('^# CLAUDE%.md') ~= nil
        or text:match('^<') ~= nil
end

local function codex_title_from_message(message)
    local text = vim.trim(message or '')
    if text == '' then
        return nil
    end

    if not is_injected(text) then
        return text
    end

    local marker = 'Sharing the following file as context:'
    local marker_end
    local start = 1
    while true do
        local _, finish = text:find(marker, start, true)
        if not finish then
            break
        end

        local path_start = finish + 1
        local tail = text:sub(path_start)
        local path_end
        for _, ext in ipairs({
            '.jsonl',
            '.lua',
            '.md',
            '.py',
            '.json',
            '.toml',
            '.yaml',
            '.yml',
            '.txt',
        }) do
            local ext_start, ext_end = tail:find(ext, 1, true)
            if ext_start and (not path_end or ext_end < path_end) then
                path_end = ext_end
            end
        end

        for _, boundary in ipairs({
            tail:find('\n', 1, true),
            tail:find('#', 1, true),
            tail:find(marker, 1, true),
        }) do
            if boundary and (not path_end or boundary - 1 < path_end) then
                path_end = boundary - 1
            end
        end

        marker_end = path_start + (path_end or 0) - 1
        start = finish + 1
    end

    if marker_end then
        text = vim.trim(text:sub(marker_end + 1))
    else
        while text:match('^Sharing `') do
            local stripped, count =
                text:gsub('^Sharing `[^`]+`:%s*%-%-%-\n.-\n%-%-%-%s*', '', 1)
            if count == 0 then
                return nil
            end
            text = vim.trim(stripped)
        end
    end

    if text == '' or is_injected(text) then
        return nil
    end

    local heading = text:match('^#+%s*([^\n]+)')
    if heading then
        return heading
    end

    for line in text:gmatch('[^\r\n]+') do
        line = vim.trim(line)
        if line ~= '' and line ~= 'image' and not is_injected(line) then
            return line
        end
    end
end

-- Scan the agents' on-disk session stores. Unlike the ACP `session/list` RPC
-- (which the agent scopes to the request cwd), these discover every session
-- across all working directories, which is what lets us resume from anywhere
local scanners = {}

-- Claude Code stores one <sessionId>.jsonl per session under a per-cwd project
-- dir. The true cwd (needed to load) lives in the message lines; ACP sessions
-- also carry an `aiTitle`/`lastPrompt` we use as a label
scanners.claude_code = function()
    local entries = {}
    local files =
        vim.fn.glob(vim.fn.expand('~/.claude/projects') .. '/*/*.jsonl', true, true)
    for _, file in ipairs(files) do
        local cwd, ai_title, last_prompt
        for _, d in ipairs(read_jsonl(file, 500)) do
            cwd = cwd or d.cwd
            ai_title = d.aiTitle or ai_title
            last_prompt = d.lastPrompt or last_prompt
        end
        if cwd then
            entries[#entries + 1] = {
                adapter = 'claude_code',
                session_id = vim.fn.fnamemodify(file, ':t:r'),
                cwd = cwd,
                title = clean_title(ai_title or last_prompt),
                updated_at = mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
            }
        end
    end
    return entries
end

-- Codex stores date-bucketed rollout-*.jsonl files. The first `session_meta`
-- line holds the id/cwd/timestamp; the first real prompt is the label
scanners.codex = function()
    local entries = {}
    local files = vim.fn.glob(
        vim.fn.expand('~/.codex/sessions') .. '/**/rollout-*.jsonl',
        true,
        true
    )
    for _, file in ipairs(files) do
        local meta, title = nil, nil
        for _, d in ipairs(read_jsonl(file, 300)) do
            if d.type == 'session_meta' then
                meta = d.payload
            elseif
                not title
                and d.type == 'event_msg'
                and d.payload
                and d.payload.type == 'user_message'
            then
                local msg = d.payload.message
                title = codex_title_from_message(msg)
                if title then
                    break
                end
            end
        end
        if meta and meta.id and meta.cwd then
            entries[#entries + 1] = {
                adapter = 'codex',
                session_id = meta.id,
                cwd = meta.cwd,
                title = clean_title(title),
                updated_at = (
                    meta.timestamp and utils.timestamp_from_iso(meta.timestamp)
                ) or mtime(file),
                size = (vim.uv.fs_stat(file) or {}).size or 0,
                path = file,
            }
        end
    end
    return entries
end

-- Bring up the ACP connection. Only needed to load a session (listing reads
-- disk), so we defer it until after a pick to keep the picker instant and avoid
-- racing the connection setup against the picker opening
local function ensure_connection(chat)
    local handler = require('codecompanion.interactions.chat.acp.handler').new(chat)
    if not handler:ensure_connection() then
        utils.notify('No ACP connection available', vim.log.levels.WARN)
        return false
    end

    if not chat.acp_connection:can_load_session() then
        utils.notify(
            'This ACP adapter does not support loading sessions',
            vim.log.levels.WARN
        )
        return false
    end

    return true
end

-- Telescope display: <icon> <title> (~weight)  <clock> <time>  <cwd>
local function display_entry(picker_entry)
    local e = picker_entry.value
    local icon = e.display_icon or state_helpers.provider_icon(e.adapter)
    local title = pad_right(
        e.display_title or trim_chars(e.title or e.session_id, TITLE_WIDTH),
        e.display_title_width or 0
    )
    local weight = e.display_weight or fmt_weight(e.size)
    local weight_pad = string.rep(
        ' ',
        math.max((e.display_weight_width or 0) - vim.fn.strdisplaywidth(weight), 0)
    )
    local time = pad_right(
        e.display_time or (e.updated_at and utils.make_relative(e.updated_at) or '?'),
        e.display_time_width or 0
    )
    local cwd = e.display_cwd or (e.cwd and vim.fn.fnamemodify(e.cwd, ':~') or '')
    local meta = string.format('(%s)%s   %s %s', weight, weight_pad, CLOCK, time)
    local line = string.format('%s %s  %s  %s', icon, title, meta, cwd)

    local title_end = #icon + 1 + #title
    return line, {
        { { title_end + 1, #line }, 'Comment' },
    }
end

local function load_entry(chat, entry)
    if not ensure_connection(chat) then
        return
    end

    -- The agent locates and roots the session by the cwd passed to session/load,
    -- so switch to the session's original cwd for the duration of the load
    local previous_cwd = vim.fn.getcwd()
    if entry.cwd and vim.fn.isdirectory(entry.cwd) == 1 then
        vim.api.nvim_set_current_dir(entry.cwd)
    end

    local updates = {}
    local ok = chat.acp_connection:load_session(entry.session_id, {
        on_session_update = function(update)
            table.insert(updates, update)
        end,
    })

    if vim.fn.getcwd() ~= previous_cwd and vim.fn.isdirectory(previous_cwd) == 1 then
        vim.api.nvim_set_current_dir(previous_cwd)
    end

    if not ok then
        return utils.notify('Failed to load ACP session', vim.log.levels.ERROR)
    end

    require('codecompanion.interactions.chat.acp.commands').link_buffer_to_session(
        chat.bufnr,
        chat.acp_connection.session_id
    )
    require('codecompanion.interactions.chat.acp.render').restore_session(chat, updates)

    if entry.title then
        chat:set_title(entry.title)
    end

    utils.fire('ACPChatRestored', {
        bufnr = chat.bufnr,
        id = chat.id,
        session_id = chat.acp_connection.session_id,
        title = chat.title,
    })
    utils.notify(
        'Resumed ACP session: ' .. (entry.title or entry.session_id),
        vim.log.levels.INFO
    )
end

function M.browse(chat)
    if not chat or not chat.adapter or chat.adapter.type ~= 'acp' then
        return utils.notify(
            'ACP sessions require an ACP chat adapter',
            vim.log.levels.WARN
        )
    end

    if chat.cycle > 1 then
        return utils.notify(
            'ACP sessions must be loaded before submitting messages',
            vim.log.levels.WARN
        )
    end

    local scan = scanners[chat.adapter.name]
    if not scan then
        return utils.notify(
            'No session scanner for adapter: ' .. chat.adapter.name,
            vim.log.levels.WARN
        )
    end

    local entries = scan()
    table.sort(entries, function(a, b)
        return (a.updated_at or 0) > (b.updated_at or 0)
    end)
    prepare_display(entries)

    if #entries == 0 then
        return utils.notify('No ACP sessions found', vim.log.levels.INFO)
    end

    -- Telescope picker so we can attach a delete action; <CR> resumes,
    -- d/<A-d> deletes the selected session and refreshes the list
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    local function make_finder()
        return finders.new_table({
            results = entries,
            entry_maker = function(e)
                return {
                    value = e,
                    display = display_entry,
                    ordinal = (e.title or '') .. ' ' .. (e.cwd or ''),
                }
            end,
        })
    end

    pickers
        .new({}, {
            prompt_title = 'ACP Sessions (<A-d>:delete)',
            finder = make_finder(),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selection_hl =
                    vim.api.nvim_get_hl(0, { name = 'TelescopeSelection', link = false })
                selection_hl.bold = true
                vim.api.nvim_set_hl(0, 'CodeCompanionSessionSelection', selection_hl)
                vim.wo[picker.results_win].winhighlight = table.concat(
                    vim.tbl_filter(function(part)
                        return part ~= ''
                    end, {
                        vim.wo[picker.results_win].winhighlight,
                        'TelescopeSelection:CodeCompanionSessionSelection',
                    }),
                    ','
                )

                actions.select_default:replace(function()
                    local sel = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if sel then
                        load_entry(chat, sel.value)
                    end
                end)

                local function delete()
                    local sel = action_state.get_selected_entry()
                    if not sel then
                        return
                    end
                    local e = sel.value
                    if not delete_session(e.path) then
                        return utils.notify(
                            'Failed to delete session',
                            vim.log.levels.ERROR
                        )
                    end
                    for i = #entries, 1, -1 do
                        if entries[i] == e then
                            table.remove(entries, i)
                        end
                    end
                    action_state
                        .get_current_picker(prompt_bufnr)
                        :refresh(make_finder(), { reset_prompt = false })
                    utils.notify(
                        'Deleted session: ' .. (e.title or e.session_id),
                        vim.log.levels.INFO
                    )
                end

                map('n', 'd', delete)
                map('i', '<A-d>', delete)
                return true
            end,
        })
        :find()
end

return M
