local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

return require('packer').startup(function(use)
    -- TODO: automatically install plugins
    use('wbthomason/packer.nvim')

    use{'winston0410/commented.nvim',
    config = function() require('commented').setup({
            comment_padding = " ", 
            keybindings = {
                n = "<Leader>cc",
                v = "<Leader>cc", 
                nl = "<Leader>cc"
            }
        }) end
    }

    use("nathom/tmux.nvim")

    if packer_bootstrap then
        require('packer').sync()
   end
end)
