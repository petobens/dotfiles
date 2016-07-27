" Place this file in your home directory as .vimrc
if has('win32') || has('win64')
   source C:/OD/OneDrive/vimfiles/vimrc
elseif isdirectory(expand('$HOME/OneDrive/'))
    source ~/OneDrive/vimfiles/vimrc
else
    " For linux
    source ~/pedrof/vimfiles/vimrc
end
