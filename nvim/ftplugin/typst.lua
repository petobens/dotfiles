local api = vim.api
local ts_select = require('nvim-treesitter-textobjects.select')

local u = require('utils')
local read_file = u.read_file

-- Options
vim.opt_local.foldexpr = vim.treesitter.foldexpr
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldtext = ''
vim.opt_local.formatexpr = ''
vim.opt_local.formatoptions = 'trj'
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.spell = true
vim.opt_local.tabstop = 2
vim.opt_local.textwidth = 80

-- Paths
local function is_main_source(name, path)
    if not name:match('%.typ$') then
        return false
    end

    local content = read_file(vim.fs.joinpath(path, name))
    if not content then
        return false
    end
    content = '\n' .. content

    -- Record local package names, then identify a main file by a matching
    -- `#show: <package>.with(...)`; chapters may import without applying one
    local imports = {}
    for package in content:gmatch('\n%s*#import%s+"@local/([%w-]+):[^"]+"') do
        imports[package] = true
    end
    for template in content:gmatch('\n%s*#show%s*:%s*([%w-]+)%.with%s*%(') do
        if imports[template] then
            return true
        end
    end
    return false
end

local function resolve_main(source)
    local directory = vim.fs.dirname(source)
    if is_main_source(vim.fs.basename(source), directory) then
        return source
    end

    return vim.fs.find(is_main_source, {
        path = directory,
        stop = vim.fs.dirname(vim.fs.dirname(directory)),
        type = 'file',
        upward = true,
    })[1] or source
end

local function main_source(bufnr)
    local source = vim.fs.normalize(api.nvim_buf_get_name(bufnr))
    if source == '' then
        return nil
    end

    local main = vim.b[bufnr].typst_main
    if main and vim.uv.fs_stat(main) then
        return main
    end

    main = resolve_main(source)
    vim.b[bufnr].typst_main = main
    return main
end

local function document_paths()
    local main = main_source(0)
    if not main then
        return nil, nil, 'Save the Typst file before compiling'
    end

    local pdf = main:gsub('%.typ$', '.pdf')
    return main, pdf
end

_G.TypstConfig = { main_source = main_source }

-- Table of contents
local state = {}
local namespace = api.nvim_create_namespace('typst_toc')
local toc_window_options = {
    'cursorline',
    'foldexpr',
    'foldlevel',
    'foldmethod',
    'foldtext',
    'list',
    'number',
    'relativenumber',
    'signcolumn',
    'spell',
    'winfixbuf',
    'winfixwidth',
    'winhighlight',
}

local function toc_document_files(main)
    local files, seen = {}, {}
    local function visit(path)
        path = vim.fs.normalize(path)
        if seen[path] then
            return
        end
        seen[path] = true
        table.insert(files, path)

        local content = read_file(path)
        if not content then
            return
        end
        -- Accept markup (#include) and code-mode (include) forms
        for relative in content:gmatch('#?include%s+"([^"]+%.typ)"') do
            local included = vim.fs.joinpath(vim.fs.dirname(path), relative)
            if vim.uv.fs_stat(included) then
                visit(included)
            end
        end
    end
    visit(main)
    return files
end

local function toc_special_entries(main)
    local content = read_file(main) or ''
    local spanish = (content:match('language%s*:%s*"([^"]+)"') or 'es') == 'es'
    local preface = content:match('preface%s*:%s*include%s+"([^"]+%.typ)"')
    local offset = content:find('#chapter%-bibliographies%s*%(')
        or content:find('#bibliography%s*%(')
    local title = offset and content:sub(offset):match('title%s*:%s*%[([^%]]+)%]')
    return {
        preface = preface and {
            name = spanish and 'Prefacio' or 'Preface',
            path = vim.fs.joinpath(vim.fs.dirname(main), preface),
            lnum = 1,
        },
        bibliography = offset and {
            name = title and vim.trim(title)
                or (spanish and 'Bibliografía' or 'Bibliography'),
            path = main,
            lnum = select(2, content:sub(1, offset):gsub('\n', '')) + 1,
        },
        appendix_name = spanish and 'Apéndice' or 'Appendix',
        is_book = content:find('@local/latex%-book') ~= nil,
        is_slides = content:find('@local/mutt%-slides') ~= nil,
    }
end

local function toc_clear_source_highlight()
    if state.highlight_bufnr and api.nvim_buf_is_valid(state.highlight_bufnr) then
        api.nvim_buf_clear_namespace(state.highlight_bufnr, namespace, 0, -1)
    end
    state.highlight_bufnr = nil
end

local function toc_highlight_source()
    toc_clear_source_highlight()
    local entry = state.entries and state.entries[api.nvim_win_get_cursor(0)[1]]
    if not entry then
        return
    end
    state.highlight_bufnr = vim.fn.bufadd(entry.path)
    api.nvim_buf_set_extmark(state.highlight_bufnr, namespace, entry.lnum - 1, 0, {
        end_row = entry.lnum,
        hl_eol = true,
        hl_group = 'AerialLine',
        priority = 4097, -- Match Aerial's line-highlight priority
    })
end

local function toc_render(outlines, special, source_path, source_lnum)
    local lines = special.preface and { special.preface.name } or {}
    local entries = special.preface and { special.preface } or {}

    -- Flatten Tinymist's symbol trees into display lines and jump targets
    local appendix_index = 0
    local appendix_depth = special.is_slides and 0 or 1
    local function toc_add(symbols, path, prefix, depth, index, appendix)
        for _, symbol in ipairs(symbols or {}) do
            if symbol.kind == vim.lsp.protocol.SymbolKind.Namespace then
                index = index + 1
                local range = symbol.selectionRange or symbol.range
                local lnum = range.start.line + 1
                local number = prefix and prefix .. '.' .. index or tostring(index)
                if appendix and lnum > appendix and depth == appendix_depth then
                    appendix_index = appendix_index + 1
                    if
                        not special.is_book
                        and not special.is_slides
                        and appendix_index == 1
                    then
                        table.insert(lines, special.appendix_name)
                        table.insert(entries, { path = path, lnum = appendix })
                    end
                    number = (special.is_book and prefix .. '.' or '')
                        .. string.char(64 + appendix_index)
                end
                local entry = {
                    path = path,
                    lnum = lnum,
                    col = range.start.character,
                    number = number,
                    depth = depth,
                }
                local line = string.rep('  ', depth) .. number .. ' ' .. symbol.name
                table.insert(lines, line)
                table.insert(entries, entry)
                toc_add(symbol.children, path, number, depth + 1, 0, appendix)
            else
                index = toc_add(symbol.children, path, prefix, depth, index, appendix)
            end
        end
        return index
    end
    local root_index = 0
    for _, outline in ipairs(outlines) do
        appendix_index = 0
        root_index =
            toc_add(outline.symbols, outline.path, nil, 0, root_index, outline.appendix)
    end
    if special.bibliography then
        table.insert(lines, special.bibliography.name)
        table.insert(entries, special.bibliography)
    end
    if #lines == 0 then
        lines = { 'No headings' }
    end

    -- Render the scratch buffer, then style numbers and top-level headings
    state.entries = entries
    local buffer = vim.bo[state.bufnr]
    buffer.modifiable = true
    api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
    buffer.modifiable = false
    api.nvim_buf_clear_namespace(state.bufnr, namespace, 0, -1)
    for index, entry in ipairs(entries) do
        local col = (entry.depth or 0) * 2
        if entry.number then
            api.nvim_buf_set_extmark(state.bufnr, namespace, index - 1, col, {
                end_col = col + #entry.number,
                hl_group = 'String',
            })
        end
        if col == 0 then
            api.nvim_buf_set_extmark(state.bufnr, namespace, index - 1, 0, {
                end_col = #lines[index],
                hl_group = 'Bold',
                hl_mode = 'combine',
            })
        end
    end

    -- Initially select the closest preceding heading in the source file
    local nearest
    for index, entry in ipairs(entries) do
        if entry.path == source_path then
            nearest = nearest or index
            if entry.lnum <= source_lnum then
                nearest = index
            end
        end
    end
    if nearest then
        api.nvim_win_set_cursor(state.winid, { nearest, 0 })
        vim.cmd.normal({ args = { 'zz' }, bang = true })
    end
    toc_highlight_source()
end

local function toc_release_window()
    local window = vim.wo[state.winid]
    for option, value in pairs(state.window_options) do
        window[option] = value
    end
    api.nvim_win_resize(state.winid, state.window_width, -1, {})
end

local function toc_close()
    toc_clear_source_highlight()
    if #api.nvim_list_wins() > 1 then
        api.nvim_win_close(state.winid, true)
    else
        toc_release_window()
        api.nvim_win_set_buf(state.winid, api.nvim_create_buf(true, false))
    end
    state = {}
end

local function toc_jump(split)
    local entry = state.entries[api.nvim_win_get_cursor(0)[1]]
    if not entry then
        return
    end

    local source_winid = state.source_winid
    if api.nvim_win_is_valid(source_winid) then
        toc_close()
        api.nvim_set_current_win(source_winid)
        if split then
            api.nvim_cmd({ cmd = split }, {})
        end
    else
        toc_clear_source_highlight()
        toc_release_window()
        state = {}
    end
    local bufnr = vim.fn.bufadd(entry.path)
    api.nvim_win_set_buf(0, bufnr)
    api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
    vim.cmd.normal({ args = { 'zvzz' }, bang = true })
end

local function toc_populate(main, client, source_path, source_lnum)
    local outlines = {}
    for _, path in ipairs(toc_document_files(main)) do
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)
        vim.lsp.buf_attach_client(bufnr, client.id)
        local response, err = client:request_sync('textDocument/documentSymbol', {
            textDocument = { uri = vim.uri_from_fname(path) },
        }, 2000, bufnr)
        if not response or response.err then
            err = err or (response and response.err.message) or 'request failed'
            vim.notify(
                'Typst TOC: ' .. vim.fs.basename(path) .. ': ' .. err,
                vim.log.levels.WARN
            )
        end
        local content = read_file(path) or ''
        local appendix = content:find('#appendix%s*%[')
        table.insert(outlines, {
            path = path,
            symbols = response and response.result,
            appendix = appendix
                and select(2, content:sub(1, appendix):gsub('\n', '')) + 1,
        })
    end
    toc_render(outlines, toc_special_entries(main), source_path, source_lnum)
end

local function toc_toggle()
    if state.winid and api.nvim_win_is_valid(state.winid) then
        toc_close()
        return
    end
    for _, winid in ipairs(api.nvim_list_wins()) do
        if vim.bo[api.nvim_win_get_buf(winid)].filetype == 'typsttoc' then
            api.nvim_set_current_win(winid)
            return
        end
    end
    local bufnr = api.nvim_get_current_buf()
    local main = main_source(bufnr)
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'tinymist' })[1]
    if not main or not client then
        vim.notify(
            'Save the Typst file and start Tinymist before opening its TOC',
            vim.log.levels.ERROR
        )
        return
    end

    local source_path = vim.fs.normalize(api.nvim_buf_get_name(bufnr))
    local source_lnum = api.nvim_win_get_cursor(0)[1]
    state = { source_winid = api.nvim_get_current_win() }

    -- Open and configure the sidebar
    api.nvim_cmd({ cmd = 'new', mods = { split = 'topleft', vertical = true } }, {})
    state.winid, state.bufnr = api.nvim_get_current_win(), api.nvim_get_current_buf()
    api.nvim_buf_set_name(state.bufnr, 'typst-toc')
    local buffer, window = vim.bo[state.bufnr], vim.wo[state.winid]
    state.window_width = api.nvim_win_get_width(state.winid)
    state.window_options = {}
    for _, option in ipairs(toc_window_options) do
        state.window_options[option] = window[option]
    end
    buffer.bufhidden, buffer.buftype, buffer.buflisted = 'wipe', 'nofile', false
    buffer.filetype, buffer.modifiable, buffer.swapfile = 'typsttoc', false, false
    window.cursorline, window.list, window.spell = true, false, false
    window.number, window.relativenumber, window.signcolumn = true, true, 'no'
    window.foldmethod, window.foldlevel, window.foldtext = 'expr', 99, ''
    window.foldexpr = 'indent(v:lnum + 1) > indent(v:lnum)'
        .. " && indent(v:lnum) < 4 ? '>' . (indent(v:lnum) / 2 + 1)"
        .. ' : indent(v:lnum) / 2'
    window.winhighlight = 'CursorLine:AerialLine,Folded:Normal'
    window.winfixbuf, window.winfixwidth = true, true
    api.nvim_win_resize(state.winid, 43, -1, {}) -- Match the Aerial sidebar

    -- Mappings
    vim.keymap.set('n', '<CR>', toc_jump, {
        buf = state.bufnr,
        desc = 'Typst TOC: Jump to heading',
    })
    vim.keymap.set('n', 'v', function()
        toc_jump('vsplit')
    end, { buf = state.bufnr, desc = 'Typst TOC: Jump in vertical split' })
    vim.keymap.set('n', 's', function()
        toc_jump('split')
    end, { buf = state.bufnr, desc = 'Typst TOC: Jump in horizontal split' })
    vim.keymap.set('n', 'q', toc_close, {
        buf = state.bufnr,
        desc = 'Typst TOC: Close',
    })

    -- Keep the source highlight synchronized with the TOC cursor
    api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved' }, {
        buf = state.bufnr,
        desc = 'Highlight Typst TOC heading in source',
        callback = toc_highlight_source,
    })
    api.nvim_create_autocmd('BufLeave', {
        buf = state.bufnr,
        desc = 'Clear Typst TOC source highlight',
        callback = toc_clear_source_highlight,
    })

    toc_populate(main, client, source_path, source_lnum)
end

-- Compilation
local function clear_typst_errors()
    if vim.fn.getqflist({ title = 1 }).title == 'Typst' then
        vim.fn.setqflist({}, 'r')
        vim.cmd.cclose()
    end
end

local function compile_typst(notify_success)
    if vim.fn.executable('typst') == 0 then
        vim.notify('Typst executable not found', vim.log.levels.ERROR)
        return
    end

    local main, pdf, path_error = document_paths()
    if not main or not pdf then
        vim.notify(
            path_error or 'Cannot determine Typst output path',
            vim.log.levels.ERROR
        )
        return
    end

    local root = vim.fs.dirname(main)
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.system(
        {
            'typst',
            'compile',
            '--root',
            root,
            '--diagnostic-format',
            'short',
            main,
            pdf,
        },
        { cwd = root, text = true },
        vim.schedule_wrap(function(result)
            if result.code == 0 then
                clear_typst_errors()
                if notify_success then
                    vim.notify('Compiled ' .. vim.fs.basename(pdf), vim.log.levels.INFO)
                end
                return
            end

            local stderr = vim.trim(result.stderr or '')
            local items = {}
            for line in stderr:gmatch('[^\n]+') do
                local file, lnum, col, severity, message =
                    line:match('^(.-):(%d+):(%d+): (%a+): (.+)$')
                if file then
                    if not vim.startswith(file, '/') then
                        file = vim.fs.normalize(vim.fs.joinpath(root, file))
                    end
                    table.insert(items, {
                        filename = file,
                        lnum = tonumber(lnum),
                        col = tonumber(col),
                        type = severity == 'warning' and 'W' or 'E',
                        text = message,
                    })
                end
            end
            if #items > 0 then
                vim.fn.setqflist({}, ' ', { title = 'Typst', items = items })
                vim.cmd.copen()
            else
                vim.notify(
                    stderr ~= '' and stderr or 'Typst compilation failed',
                    vim.log.levels.ERROR
                )
            end
        end)
    )
end

local function count_words()
    local bufnr = api.nvim_get_current_buf()
    local main = main_source(bufnr)
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'tinymist' })[1]
    if not main or not client then
        vim.notify('Save the Typst file and start Tinymist before counting words')
        return
    end

    local counting = true
    vim.defer_fn(function()
        if counting then
            api.nvim_echo({ { 'Counting words...' } }, false, {})
        end
    end, 500)
    client:exec_cmd({
        title = 'Count words',
        command = 'tinymist.exportText',
        arguments = { main, {}, { write = false } },
    }, { bufnr = bufnr }, function(err, result)
        counting = false
        if err then
            vim.notify(err.message, vim.log.levels.ERROR)
            return
        end
        local text = vim.base64.decode(result.data)
        local _, words = text:gsub('%S+', '')
        vim.notify(('Words: %d'):format(words))
    end)
end

local function convert_pandoc()
    local main = main_source(0)
    if not main then
        vim.notify('Save the Typst file before converting', vim.log.levels.ERROR)
        return
    end

    local markdown = main:gsub('%.typ$', '.md')
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    local result = vim.system(
        { 'pandoc', '-s', main, '-o', markdown },
        { cwd = vim.fs.dirname(main), text = true }
    ):wait()
    if result.code == 0 then
        vim.notify('Converted .typ file into .md', vim.log.levels.INFO)
    else
        vim.notify(
            string.format(
                'Pandoc failed (exit code %d): %s',
                result.code,
                result.stderr or ''
            ),
            vim.log.levels.ERROR
        )
    end
end

-- PDF viewer
local function view_pdf()
    local _, pdf, path_error = document_paths()
    if path_error then
        vim.notify(path_error, vim.log.levels.ERROR)
        return
    end
    if not pdf or not vim.uv.fs_stat(pdf) then
        vim.notify('PDF file not found: ' .. tostring(pdf), vim.log.levels.ERROR)
        return
    end
    vim.system({ 'zathura', '--fork', pdf })
end

-- Synchronization
-- Typst emits no SyncTeX data, so mark a temporary project copy; `#h(0pt)`
-- anchors the marker to the surrounding text baseline
local MARKER = '#h(0pt)#context [#metadata((..here().position(), '
    .. 'size: text.size, width: page.width, height: page.height))<nvim-sync>]'

local function zathura_call(bus_name, method, ...)
    local command = { 'gdbus', 'call', '--session', '--dest', bus_name }
    vim.list_extend(command, { '--object-path', '/org/pwmt/zathura' })
    vim.list_extend(command, { '--method', method, ... })
    return vim.system(command, { text = true }):wait().stdout or ''
end

local function zathura_instance(pdf)
    local get = 'org.freedesktop.DBus.Properties.Get'
    local pids = vim.system({ 'pgrep', '-x', 'zathura' }, { text = true }):wait()
    for pid in (pids.stdout or ''):gmatch('%d+') do
        local bus_name = 'org.pwmt.zathura.PID-' .. pid
        local filename = zathura_call(bus_name, get, 'org.pwmt.zathura', 'filename')
        if filename:find(pdf, 1, true) then
            return bus_name
        end
    end
end

local function to_points(length)
    return tonumber((length:gsub('pt$', '')))
end

local function highlight_position(pdf, position)
    local bus_name = zathura_instance(pdf)
    if not bus_name then
        vim.system({ 'zathura', '--fork', pdf })
        vim.wait(3000, function()
            bus_name = zathura_instance(pdf)
            return bus_name ~= nil
        end, 100)
    end
    if not bus_name then
        vim.notify('No Zathura instance showing ' .. pdf, vim.log.levels.ERROR)
        return
    end

    local page_width, page_height = to_points(position.width), to_points(position.height)
    if not page_width or not page_height then
        vim.notify('Could not read the page size', vim.log.levels.ERROR)
        return
    end

    -- Center prose highlights and left-align wider slide highlights
    local y, size = to_points(position.y), to_points(position.size)
    local landscape = page_width > page_height
    local width = page_width * (landscape and 0.80 or 0.70)
    local left = landscape and page_width * 0.02 or (page_width - width) / 2
    local band = string.format(
        '[(%.2f,%.2f,%.2f,%.2f)]',
        left,
        left + width,
        y - size,
        y + size / 4
    )
    local method = 'org.pwmt.zathura.HighlightRects'
    zathura_call(bus_name, method, tostring(position.page - 1), band, '[]')
end

-- Markers cannot appear on blank lines, headings, labels, or inside code groups
local function accepts_marker(line, row)
    if line:match('^%s*(.?)'):find('^[=<]?$') then
        return false
    end
    local node = vim.treesitter.get_node({ pos = { row - 1, 0 } })
    while node do
        local kind = node:type()
        if kind == 'group' then
            return false
        elseif kind == 'content' or kind == 'source_file' then
            return true
        end
        node = node:parent()
    end
    return true
end

local function forward_search()
    local main, pdf, path_error = document_paths()
    if not main then
        vim.notify(path_error, vim.log.levels.ERROR)
        return
    end
    if not vim.uv.fs_stat(pdf) then
        vim.notify('PDF file not found: ' .. pdf, vim.log.levels.ERROR)
        return
    end

    local root = vim.fs.dirname(main)
    local copy = vim.fn.tempname()
    if vim.system({ 'cp', '-r', root, copy }):wait().code ~= 0 then
        vim.notify('Could not copy the Typst project', vim.log.levels.ERROR)
        return
    end
    local source = vim.fs.normalize(api.nvim_buf_get_name(0))
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor = api.nvim_win_get_cursor(0)[1]
    vim.treesitter.get_parser(0, 'typst'):parse(true) -- Refresh syntax nodes
    while lines[cursor] and not accepts_marker(lines[cursor], cursor) do
        cursor = cursor + 1
    end
    table.insert(lines, cursor, MARKER)
    vim.fn.writefile(lines, copy .. source:sub(#root + 1))

    -- `sync=1` skips slow layout-neutral work; querying all matches keeps an
    -- empty result distinct from an evaluation failure
    local command = { 'typst', 'eval', '--root', copy, '--input', 'sync=1' }
    local query = 'query(<nvim-sync>)'
    vim.list_extend(command, { '--in', copy .. main:sub(#root + 1), query })

    vim.system(
        command,
        { text = true },
        vim.schedule_wrap(function(result)
            vim.fs.rm(copy, { recursive = true, force = true })
            if result.code ~= 0 then
                local message = vim.trim(result.stderr or '')
                vim.notify(
                    'Typst could not compile the project\n' .. message,
                    vim.log.levels.ERROR
                )
                return
            end
            local ok, found = pcall(vim.json.decode, result.stdout)
            if not ok or type(found) ~= 'table' or not found[1] then
                vim.notify(
                    'No document position for the cursor line; try a markup line',
                    vim.log.levels.ERROR
                )
                return
            end
            highlight_position(pdf, found[1].value)
        end)
    )
end

local sync_ns = api.nvim_create_namespace('typst_sync')

-- Convert a byte offset to a 0-based (row, column)
local function position_at(content, offset)
    local before = content:sub(1, offset)
    return { select(2, before:gsub('\n', '')), #before:match('[^\n]*$') }
end

-- Zathura supplies the PDF and asks each Neovim; only the project owner returns 1
function _G.TypstConfig.backward_search(pdf)
    local main = pdf:gsub('%.pdf$', '.typ')
    if not vim.uv.fs_stat(main) then
        vim.notify('No Typst source for ' .. pdf, vim.log.levels.ERROR)
        return 0
    end
    local root = vim.fs.dirname(main) .. '/'
    local holds = vim.iter(api.nvim_list_bufs()):any(function(bufnr)
        local path = vim.fs.normalize(api.nvim_buf_get_name(bufnr))
        return vim.startswith(path .. '/', root)
    end)
    if not holds then
        return 0
    end
    local selection = vim.trim(vim.fn.getreg('+'))
    if selection == '' then
        vim.notify('Select the text to find in Zathura first', vim.log.levels.WARN)
        return 0
    end

    -- Undo PDF hyphenation and progressively shorten cross-line matches
    local words = {}
    for word in selection:gsub('%-%s+', ''):gmatch('%S+') do
        table.insert(words, vim.pesc(word))
    end
    local sources = {}
    for _, path in ipairs(toc_document_files(main)) do
        local content = read_file(path) or ''
        table.insert(sources, { path = path, content = content })
    end

    while #words > 0 do
        local pattern = table.concat(words, '%s+')
        local matches = {}
        for _, source in ipairs(sources) do
            local offset = 1
            while offset <= #source.content do
                local start, finish = source.content:find(pattern, offset)
                if not start then
                    break
                end
                local from = position_at(source.content, start - 1)
                local to = position_at(source.content, finish)
                table.insert(matches, {
                    path = source.path,
                    from = from,
                    to = to,
                    text = source.content:match('[^\n]*', start - from[2]),
                })
                offset = start + 1
            end
        end
        if #matches == 1 then
            local match = matches[1]
            local bufnr = vim.fn.bufadd(match.path)
            vim.fn.bufload(bufnr)
            local winid = api.nvim_get_current_win()
            local function editable(candidate)
                return api.nvim_win_get_config(candidate).relative == ''
                    and not vim.wo[candidate].winfixbuf
            end
            local windows = api.nvim_list_wins()
            -- If the source is already open, jump there without changing another buffer
            local source_winid = vim.iter(windows):find(function(candidate)
                return editable(candidate) and api.nvim_win_get_buf(candidate) == bufnr
            end)
            if source_winid then
                winid = source_winid
            elseif not editable(winid) then
                -- For a float or fixed window, jump through another normal window
                winid = vim.iter(windows):find(function(candidate)
                    local path = vim.fs.normalize(
                        api.nvim_buf_get_name(api.nvim_win_get_buf(candidate))
                    )
                    return editable(candidate) and vim.startswith(path .. '/', root)
                end) or vim.iter(windows):find(editable)
            end
            if not winid then
                vim.notify(
                    'No editable window for the Typst source',
                    vim.log.levels.ERROR
                )
                return 0
            end
            api.nvim_set_current_win(winid)
            api.nvim_win_set_buf(winid, bufnr)
            api.nvim_win_set_cursor(winid, { match.from[1] + 1, match.from[2] })
            -- Folds only exist once the buffer has been drawn in the window
            vim.schedule(function()
                pcall(vim.cmd.normal, { args = { 'zOzz' }, bang = true })
            end)
            vim.hl.range(
                bufnr,
                sync_ns,
                'Visual',
                match.from,
                match.to,
                { timeout = 1000 }
            )
            return 1
        elseif #matches > 1 then
            local items = vim.tbl_map(function(match)
                return {
                    filename = match.path,
                    lnum = match.from[1] + 1,
                    col = match.from[2] + 1,
                    end_lnum = match.to[1] + 1,
                    end_col = match.to[2] + 1,
                    text = match.text,
                }
            end, matches)
            vim.fn.setqflist({}, ' ', {
                title = 'Typst backward search',
                items = items,
            })
            local id = vim.fn.getqflist({ id = 0 }).id
            vim.schedule(function()
                require('telescope.builtin').quickfix({
                    id = id,
                    prompt_title = 'Typst backward search',
                })
            end)
            return 1
        end
        table.remove(words)
    end
    vim.notify('Selection not found in the Typst sources', vim.log.levels.WARN)
    return 0
end

-- Editing
local function edit_main()
    local main = main_source(0)
    if not main then
        vim.notify(
            'Save the Typst file before opening its main file',
            vim.log.levels.ERROR
        )
        return
    end
    u.split_open(main)
end

local function edit_bibliography()
    local main = main_source(0)
    if not main then
        vim.notify(
            'Save the Typst file before opening its bibliography',
            vim.log.levels.ERROR
        )
        return
    end

    local content = read_file(main) or ''
    local relative = content:match('bibliography%s*%(%s*"([^"]+%.bib)"')
        or content:match('bibliography%s*%(%s*"([^"]+%.ya?ml)"')
        or content:match('read%s*%(%s*"([^"]+%.bib)"')
        or content:match('read%s*%(%s*"([^"]+%.ya?ml)"')
    local bibliography = relative and vim.fs.joinpath(vim.fs.dirname(main), relative)
    if not bibliography or not vim.uv.fs_stat(bibliography) then
        vim.notify('Typst bibliography file not found', vim.log.levels.ERROR)
        return
    end
    u.split_open(bibliography)
end

local function edit_figure()
    local asset = api.nvim_get_current_line():match('"([^"]+%.%w+)"')
    if not asset then
        vim.notify('No figure path on this line', vim.log.levels.ERROR)
        return
    end

    local main = main_source(0)
    if not main then
        vim.notify('Save the Typst file before opening a figure', vim.log.levels.ERROR)
        return
    end

    local name = vim.fs.basename(asset):gsub('%.%w+$', '.typ')
    local source = vim.fs.find({ name }, {
        type = 'file',
        path = vim.fs.dirname(main),
    })[1]
    if not source then
        vim.notify('Figure source not found: ' .. name, vim.log.levels.ERROR)
        return
    end
    u.split_open(source)
end

local function toggle_equation()
    if not package.loaded.luasnip then
        vim.cmd.packadd('LuaSnip')
        require('plugin-config.luasnip_config')
    end
    local first = math.min(vim.fn.line('v'), vim.fn.line('.')) - 1
    local last = math.max(vim.fn.line('v'), vim.fn.line('.'))
    local context =
        table.concat(api.nvim_buf_get_lines(0, math.max(0, first - 1), last, false))
    local trigger = context:find('#equation%s*%(') and 'ueq' or 'equ'
    api.nvim_feedkeys(vim.keycode('<C-s>' .. trigger .. '<C-s>'), 'm', false)
end

-- Lists
local function continue_list()
    local row = api.nvim_win_get_cursor(0)[1]
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    local indent, marker = line:match('^(%s*)([-+]%s+)')
    if not marker then
        return '<CR>'
    end
    if line == indent .. marker then
        return '<C-U>'
    end
    return '<CR>' .. marker
end

-- Autocmds
api.nvim_create_autocmd('BufWritePost', {
    buf = 0,
    desc = 'Compile Typst document on save',
    callback = function(args)
        vim.b[args.buf].typst_main = nil
        if not vim.fs.root(args.buf, 'typst.toml') then
            compile_typst(false)
        end
    end,
})

-- Mappings
---- Compilation
vim.keymap.set({ 'n', 'i' }, '<F7>', function()
    compile_typst(true)
end, { buf = 0, desc = 'Compile Typst document' })
vim.keymap.set('n', '<Leader>cm', convert_pandoc, {
    buf = 0,
    desc = '[C]onvert to [m]arkdown (Pandoc)',
})
vim.keymap.set('n', '<Leader>vp', view_pdf, {
    buf = 0,
    desc = '[V]iew PDF [p]review in Zathura',
})
vim.keymap.set('n', '<Leader>sl', forward_search, {
    buf = 0,
    desc = '[S]ource forward search to PDF [l]ocation (Zathura)',
})
vim.keymap.set('n', '<Leader>cw', count_words, { buf = 0, desc = '[C]ount [w]ords' })

---- Editing
vim.keymap.set(
    'n',
    '<Leader>em',
    edit_main,
    { buf = 0, desc = '[E]dit [m]ain Typst file' }
)
vim.keymap.set('n', '<Leader>eb', edit_bibliography, {
    buf = 0,
    desc = '[E]dit [b]ibliography (Typst)',
})
vim.keymap.set('n', '<Leader>ef', edit_figure, {
    buf = 0,
    desc = '[E]dit [f]igure source (Typst)',
})
vim.keymap.set('x', '<Leader>ts', toggle_equation, {
    buf = 0,
    desc = '[T]oggle equation numbering [s]tatus (Typst)',
})

---- Text objects
vim.keymap.set({ 'x', 'o' }, 'im', function()
    ts_select.select_textobject('@math.inner', 'textobjects')
end, { buf = 0, desc = 'Select inside math' })
vim.keymap.set({ 'x', 'o' }, 'am', function()
    ts_select.select_textobject('@math.outer', 'textobjects')
end, { buf = 0, desc = 'Select around math' })

---- Table of contents
vim.keymap.set('n', '<Leader>tc', toc_toggle, {
    buf = 0,
    desc = '[T]able of [c]ontents: toggle (Typst)',
})

---- Lists
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buf = 0, desc = 'Continue Typst list' }
)
