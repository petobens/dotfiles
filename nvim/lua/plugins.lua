local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        lazypath,
    })
end
vim.opt.runtimepath:prepend(lazypath)

-- Plugin list
local plugins = {
    -- Appearance
    {
        'olimorris/onedarkpro.nvim',
        config = function()
            require('plugin-config.onedark_config')
        end,
        priority = 1000, -- load first
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = {
            'petobens/lualine-lsp-progress.nvim',
        },
        config = function()
            require('plugin-config.lualine_config')
        end,
    },
    {
        'luukvbaal/statuscol.nvim',
        config = function()
            require('plugin-config.statuscol_config')
        end,
    },

    -- Editing
    {
        'kylechui/nvim-surround',
        config = function()
            require('plugin-config.surround_config')
        end,
    },
    {
        'NvChad/nvim-colorizer.lua',
        config = function()
            require('plugin-config.colorizer_config')
        end,
        keys = '<Leader>cz',
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require('plugin-config.indentlines_config')
        end,
    },
    {
        'ggandor/leap.nvim',
        dependencies = {
            'ggandor/flit.nvim',
        },
        config = function()
            require('plugin-config.leap_config')
        end,
    },

    -- Linters & formatting
    {
        'mfussenegger/nvim-lint',
        config = function()
            require('plugin-config.diagnostics_config') -- Also load diagnostics here
            require('plugin-config.nvimlint_config')
        end,
    },
    {
        'stevearc/conform.nvim',
        config = function()
            require('plugin-config.conform_config')
        end,
    },

    -- LSP, treesitter and completion
    {
        'williamboman/mason.nvim',
        dependencies = 'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = function()
            require('plugin-config.mason_config')
        end,
    },
    { 'williamboman/mason-lspconfig.nvim' },
    {
        'neovim/nvim-lspconfig',
        config = function()
            require('plugin-config.lsp_config')
        end,
    },
    { 'folke/lazydev.nvim' },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'andersevenrud/cmp-tmux',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-emoji',
            'onsails/lspkind.nvim',
            'petertriho/cmp-git',
        },
        config = function()
            require('plugin-config.cmp_config')
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
        config = function()
            require('plugin-config.treesitter_config')
        end,
    },
    {
        'm-demare/hlargs.nvim',
        config = function()
            require('plugin-config.hlargs_config')
        end,
    },
    {
        'zbirenbaum/copilot.lua',
        dependencies = {
            'zbirenbaum/copilot-cmp',
        },
        event = 'InsertEnter',
        config = function()
            require('plugin-config.copilot_config')
        end,
    },
    {
        'petobens/ChatGPT.nvim',
        branch = 'chatgpt-all-changes',
        dependencies = {
            'MunifTanjim/nui.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
        },
        keys = {
            '<Leader>cg',
            '<Leader>ca',
            '<Leader>cp',
            { '<Leader>ce', mode = { 'n', 'v' } },
            { '<Leader>cr', mode = { 'n', 'v' } },
        },
        config = function()
            require('plugin-config.chatgpt_config')
        end,
    },

    -- Snippets
    {
        'L3MON4D3/LuaSnip',
        dependencies = {
            'saadparwaiz1/cmp_luasnip',
            'benfowler/telescope-luasnip.nvim',
        },
        event = 'InsertEnter',
        config = function()
            require('plugin-config.luasnip_config')
        end,
    },

    -- Telescope and file/code exploring
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            'debugloop/telescope-undo.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'nvim-telescope/telescope-z.nvim',
            'rafi/telescope-thesaurus.nvim',
        },
        config = function()
            require('plugin-config.telescope_config')
        end,
    },
    {
        'AckslD/nvim-neoclip.lua',
        config = function()
            require('plugin-config.neoclip_config')
        end,
    },
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('plugin-config.nvimtree_config')
        end,
    },
    {
        'stevearc/aerial.nvim',
        config = function()
            require('plugin-config.aerial_config')
        end,
    },

    -- Runners and terminal
    {
        'stevearc/overseer.nvim',
        config = function()
            require('plugin-config.overseer_config')
        end,
    },
    {
        'akinsho/toggleterm.nvim',
        config = function()
            require('plugin-config.toggleterm_config')
        end,
    },
    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-neotest/neotest-python',
            'nvim-neotest/nvim-nio',
        },
        config = function()
            require('plugin-config.neotest_config')
        end,
    },
    {
        'yorickpeterse/nvim-pqf',
        config = function()
            require('plugin-config.pqf_config')
        end,
    },
    {
        'michaelb/sniprun',
        build = 'sh install.sh',
        config = function()
            require('plugin-config.sniprun_config')
        end,
    },

    -- Utilities
    { 'jamessan/vim-gnupg' },
    {
        'nathom/tmux.nvim',
        config = function()
            require('plugin-config.tmux_config')
        end,
    },
    {
        '3rd/image.nvim',
        ft = 'markdown',
        config = function()
            require('plugin-config.image_config')
        end,
    },
    {
        'andymass/vim-matchup',
        config = function()
            require('plugin-config.matchup_config')
        end,
        event = 'BufReadPost',
    },
    {
        'echasnovski/mini.align',
        config = function()
            require('plugin-config.mini_align_config')
        end,
    },
    {
        'lambdalisue/suda.vim',
        cmd = { 'SudaWrite', 'SudaRead' },
    },
    {
        'nyngwang/NeoZoom.lua',
        config = function()
            require('plugin-config.neozoom_config')
        end,
        keys = '<Leader>zw',
    },

    -- Filetype-specific
    ---- Git
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('plugin-config.gitsigns_config')
        end,
    },
    {
        'tpope/vim-fugitive',
        dependencies = {
            'aymericbeaumet/vim-symlink',
            'shumphrey/fugitive-gitlab.vim',
            'tommcdo/vim-fubitive',
            'tpope/vim-rhubarb',
        },
        config = function()
            require('plugin-config.fugitive_config')
        end,
    },
    ---- Latex
    {
        'lervag/vimtex',
        dependencies = { 'jbyuki/nabla.nvim' },
        config = function()
            require('plugin-config.vimtex_config')
        end,
    },
    ---- SQL
    {
        'kndndrj/nvim-dbee',
        dependencies = {
            'MunifTanjim/nui.nvim',
            {
                'MattiasMTS/cmp-dbee',
                ft = { 'sql' },
                lazy = true,
            },
        },
        build = function()
            require('dbee').install()
        end,
        keys = '<Leader>db',
        config = function()
            require('plugin-config.dbee_config')
        end,
    },
}

-- Lazy plugin setup
require('lazy').setup(plugins, {
    -- Don't lazy load by default instead load during startup; use
    -- keys/events/cmds/ft in plugin config if lazy laoding is required
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
vim.keymap.set('n', '<Leader>lz', '<Cmd>Lazy<CR>')
vim.keymap.set('n', '<Leader>bu', '<Cmd>Lazy sync<CR>')
vim.keymap.set('n', '<Leader>ul', '<Cmd>Lazy log<CR>')
