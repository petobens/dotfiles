local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

return require('packer').startup(function(use)
    -- TODO: automatically install plugins
    use('wbthomason/packer.nvim')

    -- Appearance
    -- See https://github.com/lukas-reineke/onedark.nvim/blob/master/lua/onedark.lua
    use({
        'navarasu/onedark.nvim',
        config = function()
            require('plugins/onedark')
        end,
    })
    use({
        'nvim-lualine/lualine.nvim',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function()
            require('plugins/lualine')
        end,
    })
    -- Maybe try https://github.com/akinsho/bufferline.nvim
    -- use({
        -- 'romgrk/barbar.nvim',
        -- requires = {'kyazdani42/nvim-web-devicons'},
        -- config = function()
            -- require('plugins/barbar')
        -- end,
    -- })

    -- Editing
    use({
        'winston0410/commented.nvim',
        config = function()
            require('plugins/commented_cfg')
        end,
    })
    use({
        -- FIXME: doesn't allow for repeat?
        'blackCauldron7/surround.nvim',
        config = function()
            require('surround').setup({
                mappings_style = 'surround'
            })
        end
    })
    use({
        'norcalli/nvim-colorizer.lua',
        config = function()
            require('plugins/colorizer')
        end,
    })
    use({
        'Pocco81/HighStr.nvim',
        config = function()
            require('plugins/high_str')
        end,
    })
    -- use({
        -- 'lukas-reineke/indent-blankline.nvim',
        -- config = function()
            -- require('plugins/indent_lines')
        -- end,
    -- })

    -- LSP and completion
    use({
        'neovim/nvim-lspconfig'
    })
    use({
        'williamboman/nvim-lsp-installer',
        config = function()
            require('plugins/lsp_installer')
        end,
    })
    use({
        'folke/trouble.nvim',
        requires = 'kyazdani42/nvim-web-devicons',
        config = function()
            require('plugins/trouble_cfg')
        end
    })
    use({
        'hrsh7th/nvim-cmp',
        requires = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
        },
        config = function()
            require('plugins/cmp_cfg')
        end,
    })

   use({
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require('plugins/treesitter')
        end,
    })

    -- Telescope and file exploring
    use({
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}},
        config = function()
            require('plugins/telescope')
        end,
    })
    use({
        'nvim-telescope/telescope-z.nvim',
        requires = {
            {'nvim-telescope/telescope.nvim'},
            {'nvim-lua/popup.nvim'},
        },
    })
    use({
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function()
            require('plugins/nvim_tree')
        end,
    })

    -- Git
    use({
        'lewis6991/gitsigns.nvim',
        requires = {
            'nvim-lua/plenary.nvim'
        },
        config = function()
            require('plugins/gitsigns_cfg')
        end
    })


    use("nathom/tmux.nvim")

    if packer_bootstrap then
        require('packer').sync()
   end
end)
