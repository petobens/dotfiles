local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({
            'git',
            'clone',
            '--depth',
            '1',
            'https://github.com/wbthomason/packer.nvim',
            install_path,
        })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    -- Automanage packer with packer
    use({
        'wbthomason/packer.nvim',
        config = function()
            require('plugin-config/packer_config')
        end,
    })

    -- Appearance
    use({
        'olimorris/onedarkpro.nvim',
        config = function()
            require('plugin-config/onedark_config')
        end,
    })
    use({
        'nvim-lualine/lualine.nvim',
        requires = {
            'kyazdani42/nvim-web-devicons',
            'WhoIsSethDaniel/lualine-lsp-progress.nvim',
        },
        config = function()
            require('plugin-config/lualine_config')
        end,
        after = 'onedarkpro.nvim',
    })

    -- Editing
    use({
        'numToStr/Comment.nvim',
        config = function()
            require('plugin-config/comment_config')
        end,
    })
    use({
        'kylechui/nvim-surround',
        config = function()
            require('plugin-config/surround_config')
        end,
    })
    use({
        'NvChad/nvim-colorizer.lua',
        config = function()
            require('plugin-config/colorizer_config')
        end,
    })
    use({
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require('plugin-config/indentlines_config')
        end,
    })

    -- LSP and completion
    use({
        'williamboman/mason.nvim',
        requires = 'WhoIsSethDaniel/mason-tool-installer.nvim',
        config = function()
            require('plugin-config/mason_config')
        end,
    })
    use('williamboman/mason-lspconfig.nvim')
    use({
        'neovim/nvim-lspconfig',
        config = function()
            require('plugin-config/lsp_config')
        end,
    })
    use({ 'folke/lua-dev.nvim' })
    use({
        'jose-elias-alvarez/null-ls.nvim',
        config = function()
            require('plugin-config/null_ls_config')
        end,
    })
    use({
        'folke/trouble.nvim',
        requires = 'kyazdani42/nvim-web-devicons',
        config = function()
            require('plugin-config/trouble_config')
        end,
    })
    use({
        'hrsh7th/nvim-cmp',
        requires = {
            'andersevenrud/cmp-tmux',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-vsnip',
            'onsails/lspkind.nvim',
        },
        config = function()
            require('plugin-config/cmp_config')
        end,
    })

    use({
        'nvim-treesitter/nvim-treesitter',
        requires = { 'nvim-treesitter/playground' },
        run = ':TSUpdate',
        config = function()
            require('plugin-config/treesitter_config')
        end,
    })

    -- Telescope and file exploring
    use({
        'nvim-telescope/telescope.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
            'nvim-telescope/telescope-z.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'kkharji/sqlite.lua',
        },
        config = function()
            require('plugin-config/telescope_config')
        end,
    })
    use({
        'kyazdani42/nvim-tree.lua',
        requires = { 'kyazdani42/nvim-web-devicons' },
        config = function()
            require('plugin-config/nvimtree_config')
        end,
    })

    -- Snippets
    use({
        'hrsh7th/vim-vsnip',
        requires = { 'hrsh7th/vim-vsnip-integ' },
        config = function()
            require('plugin-config/vsnip_config')
        end,
    })

    -- Git
    use({
        'lewis6991/gitsigns.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            require('plugin-config/gitsigns_config')
        end,
    })
    use({
        'tpope/vim-fugitive',
        requires = {
            'aymericbeaumet/vim-symlink',
            'shumphrey/fugitive-gitlab.vim',
            'tommcdo/vim-fubitive',
            'tpope/vim-rhubarb',
        },
        config = function()
            require('plugin-config/fugitive_config')
        end,
    })

    -- Utilities
    use('gioele/vim-autoswap')
    use('jamessan/vim-gnupg')
    use('nathom/tmux.nvim')
    use('tpope/vim-repeat')
    use({
        'andymass/vim-matchup',
        event = 'VimEnter',
        config = function()
            require('plugin-config/matchup_config')
        end,
    })
    use('lambdalisue/suda.vim')

    -- Automatically install plugins after cloning packer
    if packer_bootstrap then
        require('packer').sync()
    end
end)
