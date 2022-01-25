local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    packer_bootstrap = fn.system({
        'git',
        'clone',
        '--depth',
        '1',
        'https://github.com/wbthomason/packer.nvim',
        install_path,
    })
end

return require('packer').startup(function(use)
    -- TODO: automatically install plugins
    use('wbthomason/packer.nvim')

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
        },
        config = function()
            require('plugin-config/lualine_config')
        end,
    })

    -- Editing
    use({
        'winston0410/commented.nvim',
        config = function()
            require('plugin-config/commented_config')
        end,
    })
    use({
        -- FIXME: doesn't allow for repeat?
        'blackCauldron7/surround.nvim',
        config = function()
            require('surround').setup({
                mappings_style = 'surround',
            })
        end,
    })
    use({
        'norcalli/nvim-colorizer.lua',
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
    use({ 'neovim/nvim-lspconfig' })
    use({
        'williamboman/nvim-lsp-installer',
        config = function()
            require('plugin-config/lspinstaller_config')
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
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-vsnip',
            'andersevenrud/cmp-tmux',
            'onsails/lspkind-nvim',
        },
        config = function()
            require('plugin-config/cmp_config')
        end,
    })

    use({
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require('plugin-config/treesitter_config')
        end,
    })

    -- Telescope and file exploring
    use({
        'nvim-telescope/telescope.nvim',
        requires = { { 'nvim-lua/plenary.nvim' } },
        config = function()
            require('plugin-config/telescope_config')
        end,
    })
    use({
        'nvim-telescope/telescope-z.nvim',
        requires = {
            { 'nvim-telescope/telescope.nvim' },
            { 'nvim-lua/popup.nvim' },
        },
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
            'tpope/vim-rhubarb',
            'tommcdo/vim-fubitive',
            'shumphrey/fugitive-gitlab.vim',
        },
        config = function()
            require('plugin-config/fugitive_config')
        end,
    })

    use('nathom/tmux.nvim')
    use('jamessan/vim-gnupg')
    use('tpope/vim-repeat')

    if packer_bootstrap then
        require('packer').sync()
    end
end)
