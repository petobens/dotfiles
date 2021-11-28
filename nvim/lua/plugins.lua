local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

return require('packer').startup(function(use)
    -- TODO: automatically install plugins
    use('wbthomason/packer.nvim')

    use{
        'winston0410/commented.nvim',
        config = function()
            require('plugins/commented')
        end,
    }

    use{
        'navarasu/onedark.nvim',
        config = function()
            require('plugins/onedark')
        end,
    }

    use{
        'norcalli/nvim-colorizer.lua',
        config = function()
            require('plugins/colorizer')
        end,
    }
    use{
        'Pocco81/HighStr.nvim',
        config = function()
            require('plugins/high_str')
        end,
    }

    use{
        'nvim-lualine/lualine.nvim',
        requires = {'kyazdani42/nvim-web-devicons', opt = true},
        config = function()
            require('plugins/lualine')
        end,
    }

    use{
        'romgrk/barbar.nvim',
        requires = {'kyazdani42/nvim-web-devicons'},
    }

    use{
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons'},
        config = function()
            require('plugins/nvim_tree')
        end,
    }

    use{
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}},
        config = function()
            require('plugins/telescope')
        end,
    }

   use{
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }

    use("nathom/tmux.nvim")

    if packer_bootstrap then
        require('packer').sync()
   end
end)
