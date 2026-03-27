local image_utils = require('codecompanion.utils.images')

local M = {}

-- Constants
local ASSETS_DIR = vim.fs.normalize(
    vim.fs.joinpath(
        vim.env.HOME,
        'git-repos',
        'private',
        'llm-prompts',
        'md-prompts',
        'assets'
    )
)

local IMAGE_EXTS = {
    png = true,
    jpg = true,
    jpeg = true,
    webp = true,
    gif = true,
}

-- Helpers
local function collect_assets(relative_dir)
    local dir = vim.fs.joinpath(ASSETS_DIR, relative_dir)
    local stat = vim.uv.fs_stat(dir)

    if not (stat and stat.type == 'directory') then
        return nil, ('Asset directory not found: %s'):format(dir)
    end

    local assets = {}

    for name, type_ in vim.fs.dir(dir, { depth = math.huge }) do
        if type_ == 'file' then
            local path = vim.fs.joinpath(dir, name)
            local ext = vim.fs.ext(name):lower()
            table.insert(assets, {
                id = vim.fs.joinpath(relative_dir, name),
                path = path,
                is_image = IMAGE_EXTS[ext] == true,
            })
        end
    end

    table.sort(assets, function(a, b)
        return a.path < b.path
    end)

    if vim.tbl_isempty(assets) then
        return nil, ('No assets found in directory: %s'):format(dir)
    end

    return assets
end

local function get_display_dir(relative_dir, assets)
    if relative_dir ~= '' then
        return ('assets/%s'):format(relative_dir)
    end

    if vim.tbl_isempty(assets) then
        return 'assets'
    end

    local first_parent = vim.fs.dirname(assets[1].id)
    if not first_parent or first_parent == '.' then
        return 'assets'
    end

    local same_parent = vim.iter(assets):all(function(asset)
        return vim.fs.dirname(asset.id) == first_parent
    end)

    if same_parent then
        return ('assets/%s'):format(first_parent)
    end

    return 'assets'
end

local function resolve_target_dir(input)
    local dir_input = vim.fs.normalize(vim.trim(input))
    local is_under_assets_root = dir_input == ASSETS_DIR
        or vim.startswith(dir_input, ASSETS_DIR .. '/')

    if is_under_assets_root then
        return dir_input
    end

    return vim.fs.normalize(vim.fs.joinpath(ASSETS_DIR, dir_input))
end

local function read_text_file(path)
    local fd = io.open(path, 'r')
    if not fd then
        return nil
    end

    local ok, content = pcall(fd.read, fd, '*a')
    fd:close()

    if not ok then
        return nil
    end

    return content
end

-- Slash command
function M.assets(chat)
    vim.ui.input({
        prompt = 'Assets directory: ',
        default = ASSETS_DIR,
        completion = 'dir',
    }, function(input)
        if input == nil or vim.trim(input) == '' then
            return
        end

        local target_dir = resolve_target_dir(input)
        local relative_dir = vim.fs.relpath(ASSETS_DIR, target_dir) or ''

        if relative_dir == '.' then
            relative_dir = ''
        end

        local assets, err = collect_assets(relative_dir)
        if not assets then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        local loaded_images = 0
        local loaded_files = 0
        local display_dir = get_display_dir(relative_dir, assets)

        for _, asset in ipairs(assets) do
            if asset.is_image then
                local encoded = image_utils.encode_image({
                    id = asset.id,
                    path = asset.path,
                    bufnr = chat.bufnr,
                })
                if type(encoded) ~= 'string' then
                    chat:add_image_message(encoded, {
                        source = 'plugin-config.codecompanion.slash_commands.assets',
                        bufnr = chat.bufnr,
                    })
                    loaded_images = loaded_images + 1
                end
            else
                local content = read_text_file(asset.path)

                if content then
                    chat:add_context(
                        {
                            role = 'user',
                            content = string.format(
                                'Here is the content of %s:\n%s',
                                asset.path,
                                content
                            ),
                        },
                        'file',
                        string.format('<file>%s</file>', asset.id),
                        {
                            path = asset.path,
                            visible = true,
                        }
                    )
                    loaded_files = loaded_files + 1
                end
            end
        end

        chat:add_buf_message({
            role = 'llm',
            content = ('Loaded %d image(s) and %d file(s) from %s as context.'):format(
                loaded_images,
                loaded_files,
                display_dir
            ),
        })
        chat:add_buf_message({
            role = 'user',
            content = '',
        })
    end)
end

return M
