local api = vim.api
local read_file = require('utils').read_file

-- Options
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.formatoptions = 'trj'
vim.opt_local.spell = true
vim.opt_local.textwidth = 80
vim.opt_local.formatexpr = ''
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = vim.treesitter.foldexpr
vim.opt_local.foldtext = ''

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

local function toc_render(outlines, source_path, source_lnum)
    local lines, entries = {}, {}

    -- Flatten Tinymist's symbol trees into display lines and jump targets
    local function toc_add(symbols, path, prefix, depth, index)
        for _, symbol in ipairs(symbols or {}) do
            if symbol.kind == vim.lsp.protocol.SymbolKind.Namespace then
                index = index + 1
                local range = symbol.selectionRange or symbol.range
                local number = prefix and prefix .. '.' .. index or tostring(index)
                local entry = {
                    path = path,
                    lnum = range.start.line + 1,
                    col = range.start.character,
                    number = number,
                    depth = depth,
                }
                local line = string.rep('  ', depth) .. number .. ' ' .. symbol.name
                table.insert(lines, line)
                table.insert(entries, entry)
                toc_add(symbol.children, path, number, depth + 1, 0)
            else
                index = toc_add(symbol.children, path, prefix, depth, index)
            end
        end
        return index
    end
    local root_index = 0
    for _, outline in ipairs(outlines) do
        root_index = toc_add(outline.symbols, outline.path, nil, 0, root_index)
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
        local col = entry.depth * 2
        api.nvim_buf_set_extmark(state.bufnr, namespace, index - 1, col, {
            end_col = col + #entry.number,
            hl_group = 'String',
        })
        if entry.depth == 0 then
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
    api.nvim_win_set_width(state.winid, state.window_width)
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
    api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
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
        table.insert(outlines, { path = path, symbols = response and response.result })
    end
    toc_render(outlines, source_path, source_lnum)
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
    window.winhighlight = 'CursorLine:AerialLine'
    window.winfixbuf, window.winfixwidth = true, true
    api.nvim_win_set_width(state.winid, 43) -- Match the Aerial sidebar

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
        buffer = state.bufnr,
        desc = 'Highlight Typst TOC heading in source',
        callback = toc_highlight_source,
    })
    api.nvim_create_autocmd('BufLeave', {
        buffer = state.bufnr,
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
    local split = 'split'
    if api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit'
    end
    api.nvim_cmd({
        cmd = split,
        args = { main },
        magic = { file = false, bar = false },
    }, {})
end

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
    buffer = 0,
    desc = 'Compile Typst document outside packages',
    callback = function(args)
        vim.b[args.buf].typst_main = nil
        if not vim.fs.root(args.buf, 'typst.toml') then
            compile_typst(false)
        end
    end,
})

-- Mappings
vim.keymap.set({ 'n', 'i' }, '<F7>', function()
    compile_typst(true)
end, { buf = 0, desc = 'Compile Typst document' })
vim.keymap.set('n', '<Leader>vp', view_pdf, { buf = 0, desc = 'View PDF in Zathura' })
vim.keymap.set('n', '<Leader>em', edit_main, { buf = 0, desc = 'Edit Typst main file' })
vim.keymap.set('n', '<Leader>tc', toc_toggle, { buf = 0, desc = 'Toggle Typst TOC' })
vim.keymap.set(
    'i',
    '<CR>',
    continue_list,
    { expr = true, buf = 0, desc = 'Continue Typst list' }
)
