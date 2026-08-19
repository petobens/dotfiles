local api = vim.api

-- Signs of the whole buffer, grouped by line and kind, rebuilt once per redraw
local sign_cache = {}
local namespace_names = {}

-- Diagnostics and Git signs keep dedicated slots; other signs replace the number
local function sign_kind(sign)
    local name = namespace_names[sign.ns_id]
    if name == nil then
        for namespace, id in pairs(api.nvim_get_namespaces()) do
            namespace_names[id] = namespace
        end
        name = namespace_names[sign.ns_id] or sign.sign_name or ''
        namespace_names[sign.ns_id] = name
    end
    if name:find('diagnostic', 1, true) then
        return 'diagnostic'
    elseif name:find('gitsign', 1, true) then
        return 'gitsign'
    end
    return 'other'
end

local function buffer_signs(bufnr)
    if sign_cache[bufnr] then
        return sign_cache[bufnr]
    end

    local signs = { lines = {} }
    local extmarks =
        api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { type = 'sign', details = true })
    for _, extmark in ipairs(extmarks) do
        local sign = extmark[4]
        if sign.sign_text then
            local kind = sign_kind(sign)
            local lnum = extmark[2] + 1
            local line = signs.lines[lnum] or {}
            local current = line[kind]
            if not current or (sign.priority or 0) > (current.priority or 0) then
                line[kind] = sign
            end
            signs.lines[lnum] = line
            signs[kind] = true
        end
    end
    sign_cache[bufnr] = signs
    return signs
end

local function render_sign(sign, cursorline)
    if not sign then
        return ('%%#%s#  %%*'):format(cursorline and 'CursorLineSign' or 'SignColumn')
    end

    local text = sign.sign_text
    text = (text .. (' '):rep(2 - api.nvim_strwidth(text))):gsub('%%', '%%%%')
    local hl = cursorline and sign.cursorline_hl_group or sign.sign_hl_group
    return ('%%#%s#%s%%*'):format(hl or 'NoTexthl', text)
end

-- Recreate the plugin's fold glyphs without private Neovim FFI
local function render_fold(cursorline)
    local line = vim.v.lnum
    local width = api.nvim_eval_statusline('%C', {
        winid = api.nvim_get_current_win(),
        use_statuscol_lnum = line,
    }).width
    if width == 0 then
        return ''
    end

    local level = vim.fn.foldlevel(line)
    local range = math.min(level, width)
    local fillchars = vim.opt_local.fillchars:get()
    local text
    if vim.v.virtnum ~= 0 then
        text = fillchars.foldsep:rep(range)
    elseif vim.fn.foldclosed(line) == line then
        text = fillchars.foldsep:rep(range - 1) .. fillchars.foldclose
    else
        local previous = line > 1 and vim.fn.foldlevel(line - 1) or 0
        local starts = math.min(math.max(0, level - previous), range)
        if starts == 0 and vim.wo.foldmethod == 'expr' then
            local foldexpr = tostring(vim.wo.foldexpr)
            if foldexpr:find('treesitter.foldexpr', 1, true) then
                starts = tostring(vim.treesitter.foldexpr(line)):sub(1, 1) == '>' and 1
                    or 0
            end
        elseif starts == 0 and vim.wo.foldmethod == 'marker' then
            local marker = vim.split(vim.wo.foldmarker, ',', { plain = true })[1]
            local line_text = api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ''
            starts = line_text:find(marker, 1, true) and 1 or 0
        end
        text = fillchars.foldsep:rep(range - starts) .. fillchars.foldopen:rep(starts)
    end
    text = text .. (' '):rep(width - range)

    local hl = cursorline and 'CursorLineFold' or 'FoldColumn'
    return ('%%#%s#%s%%*'):format(hl, text)
end

--- Signs placed outside the diagnostic and Git columns replace the line number.
local function render_number(sign, cursorline)
    if sign then
        return '%=' .. render_sign(sign, cursorline)
    elseif not vim.wo.number and not vim.wo.relativenumber then
        return ''
    end

    local number = vim.wo.relativenumber
            and (vim.v.relnum > 0 and vim.v.relnum or (vim.wo.number and vim.v.lnum or 0))
        or vim.v.lnum
    number = tostring(number)
    return '%=' .. (' '):rep(vim.wo.numberwidth - #number) .. number
end

-- Status-column expressions require a globally accessible callback
_G.StatusColumn = {}

function _G.StatusColumn.render()
    local signs = buffer_signs(api.nvim_get_current_buf())
    -- Wrapped and virtual lines repeat neither the signs nor the line number
    local virtual = vim.v.virtnum ~= 0
    local line = not virtual and signs.lines[vim.v.lnum] or {}
    local cursorline = vim.v.relnum == 0
    local column = signs.diagnostic and render_sign(line.diagnostic, cursorline) or ''
    if signs.gitsign then
        column = column .. render_sign(line.gitsign, cursorline)
    end
    return column
        .. '%='
        .. render_fold(cursorline)
        .. (cursorline and ' ' or '')
        .. (virtual and '%=' or render_number(line.other, cursorline))
        .. ' '
end

local statuscolumn = '%{%v:lua.StatusColumn.render()%}'
api.nvim_set_hl(0, 'NoTexthl', { fg = 'NONE' })

-- Signs are placed by decoration providers, so the cache can only be trusted
-- for the duration of a single redraw
api.nvim_set_decoration_provider(api.nvim_create_namespace('statuscolumn'), {
    on_start = function()
        sign_cache = {}
    end,
})

api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
    desc = 'Set status column for the current window',
    group = api.nvim_create_augroup('StatusColumn', { clear = true }),
    callback = function()
        vim.wo.statuscolumn = vim.bo.filetype == 'NvimTree' and '' or statuscolumn
    end,
})

return statuscolumn
