-- Install lazy.nvim if missing
local lazypath = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'lazy.nvim')
if not vim.uv.fs_stat(lazypath) then
    local result = vim.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        lazypath,
    }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify(
            'Failed to clone lazy.nvim: ' .. (result.stderr or ''),
            vim.log.levels.ERROR
        )
    end
end
vim.opt.runtimepath:prepend(lazypath)

-- Helpers
local function load_plugin_config(...)
    local modules = { ... }
    return function()
        for _, m in ipairs(modules) do
            require('plugin-config.' .. m)
        end
    end
end

-- Plugin list
local plugins = {
    -- UI
    {
        'olimorris/onedarkpro.nvim',
        priority = 1000, -- load first
        config = load_plugin_config('onedark_config'),
    },
    {
        'nvim-lualine/lualine.nvim',
        config = load_plugin_config('lualine_config'),
    },
    {
        'luukvbaal/statuscol.nvim',
        config = load_plugin_config('statuscol_config'),
    },

    -- Editing
    {
        'kylechui/nvim-surround',
        config = load_plugin_config('surround_config'),
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        config = load_plugin_config('indentlines_config'),
    },
    {
        'ggandor/leap.nvim',
        dependencies = {
            'ggandor/flit.nvim',
        },
        config = load_plugin_config('leap_config'),
    },
    {
        'andymass/vim-matchup',
        event = 'BufReadPost',
        config = load_plugin_config('matchup_config'),
    },
    {
        'echasnovski/mini.align',
        config = load_plugin_config('mini_align_config'),
    },

    -- Linting & Formatting
    {
        'mfussenegger/nvim-lint',
        config = load_plugin_config('diagnostics_config', 'nvimlint_config'),
    },
    {
        'stevearc/conform.nvim',
        config = load_plugin_config('conform_config'),
    },

    -- LSP & Treesitter
    {
        'mason-org/mason.nvim',
        dependencies = 'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = load_plugin_config('mason_config'),
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = { { 'folke/lazydev.nvim', ft = 'lua' } },
        config = load_plugin_config('lsp_config'),
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
        config = load_plugin_config('treesitter_config'),
    },
    {
        'm-demare/hlargs.nvim',
        config = load_plugin_config('hlargs_config'),
    },

    -- Completion & Snippets
    {
        'Saghen/blink.cmp',
        dependencies = {
            'saghen/blink.compat',
            'fang2hou/blink-copilot',
            'mgalliou/blink-cmp-tmux',
            'Kaiser-Yang/blink-cmp-git',
            'moyiz/blink-emoji.nvim',
            'onsails/lspkind.nvim',
            { 'MattiasMTS/cmp-dbee', branch = 'ms/v2' },
        },
        build = 'cargo +nightly build --release',
        event = 'InsertEnter',
        config = load_plugin_config('blink_cmp_config'),
    },
    {
        'L3MON4D3/LuaSnip',
        dependencies = {
            'benfowler/telescope-luasnip.nvim',
        },
        event = 'InsertEnter',
        keys = '<Leader>es',
        config = load_plugin_config('luasnip_config'),
    },

    -- AI
    {
        'zbirenbaum/copilot.lua',
        event = 'InsertEnter',
        config = load_plugin_config('copilot_config'),
    },
    {
        -- 'petobens/codecompanion.nvim',
        'olimorris/codecompanion.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            { 'ravitemer/codecompanion-history.nvim' },
        },
        config = load_plugin_config('codecompanion_config'),
    },

    -- Fuzzy Finding & File Explorer
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            'debugloop/telescope-undo.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'nvim-telescope/telescope-z.nvim',
            'rafi/telescope-thesaurus.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
        },
        config = load_plugin_config('telescope_config'),
    },
    {
        'AckslD/nvim-neoclip.lua',
        config = load_plugin_config('neoclip_config'),
    },
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = load_plugin_config('nvimtree_config'),
    },
    {
        'stevearc/aerial.nvim',
        config = load_plugin_config('aerial_config'),
    },

    -- Runners & Terminal
    {
        'akinsho/toggleterm.nvim',
        config = load_plugin_config('toggleterm_config'),
    },
    {
        'nathom/tmux.nvim',
        config = load_plugin_config('tmux_config'),
    },
    {
        'stevearc/overseer.nvim',
        config = load_plugin_config('overseer_config'),
    },
    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-neotest/neotest-python',
            'nvim-neotest/nvim-nio',
        },
        config = load_plugin_config('neotest_config'),
    },
    {
        'michaelb/sniprun',
        build = 'sh install.sh',
        config = load_plugin_config('sniprun_config'),
    },
    {
        'yorickpeterse/nvim-pqf',
        config = load_plugin_config('pqf_config'),
    },

    -- Utilities
    { 'jamessan/vim-gnupg' },
    {
        '3rd/image.nvim',
        ft = 'markdown',
        config = load_plugin_config('image_config'),
    },
    {
        'HakonHarnes/img-clip.nvim',
        config = load_plugin_config('img_clip_config'),
    },
    {
        'catgoose/nvim-colorizer.lua',
        keys = '<Leader>cz',
        config = load_plugin_config('colorizer_config'),
    },
    {
        'lambdalisue/suda.vim',
        cmd = { 'SudaWrite', 'SudaRead' },
    },
    {
        'nyngwang/NeoZoom.lua',
        keys = '<Leader>zw',
        config = load_plugin_config('neozoom_config'),
    },

    -- Filetype-specific
    ---- Git
    {
        'tpope/vim-fugitive',
        dependencies = {
            'aymericbeaumet/vim-symlink',
            'shumphrey/fugitive-gitlab.vim',
            'tommcdo/vim-fubitive',
            'tpope/vim-rhubarb',
        },
        config = load_plugin_config('fugitive_config'),
    },
    {
        'lewis6991/gitsigns.nvim',
        config = load_plugin_config('gitsigns_config'),
    },

    ---- Latex
    {
        'lervag/vimtex',
        config = load_plugin_config('vimtex_config'),
    },
    {
        'Thiago4532/mdmath.nvim',
        config = load_plugin_config('mdmath_config'),
    },
    ----- Markdown
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons',
        },
        config = load_plugin_config('render_markdown_config'),
    },
    ---- SQL
    {
        'kndndrj/nvim-dbee',
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        build = function()
            require('dbee').install()
        end,
        keys = '<Leader>db',
        config = load_plugin_config('dbee_config'),
    },
}

-- Lazy plugin setup
require('lazy').setup(plugins, {
    -- Load all plugins at startup by default
    -- To enable lazy loading, specify keys/events/cmds/ft in the plugin config
    defaults = { lazy = false },
    ui = {
        size = {
            width = 1,
            height = 1,
        },
    },
    git = {
        log = { '--since=2 days ago' },
    },
    performance = {
        rtp = {
            disabled_plugins = {
                'gzip',
                'matchit',
                'matchparen',
                'netrwPlugin',
                'tarPlugin',
                'tohtml',
                'tutor',
                'zipPlugin',
            },
        },
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>lz', vim.cmd.Lazy, { desc = 'Open Lazy plugin manager' })

vim.keymap.set('n', '<Leader>bu', function()
    vim.cmd.Lazy('sync')
end, { desc = 'Sync Lazy plugins' })

vim.keymap.set('n', '<Leader>ul', function()
    vim.cmd.Lazy('log')
end, { desc = 'Show Lazy log' })
