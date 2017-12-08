#!/usr/bin/env bash
#===============================================================================
#          File: extras.sh
#        Author: Pedro Ferrari
#       Created: 14 Apr 2017
# Last Modified: 08 Dec 2017
#   Description: Mac OSX (and apps) settings
#===============================================================================
cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# iTerm
if [ -d "/Applications/iTerm.app/" ]; then
    onedarkish_iterm="$cur_dir/onedarkish.itermcolors"
    if [ -f "$onedarkish_iterm" ]; then
        defaults write -app iTerm 'Custom Color Presets' -dict-add "onedarkish" "$(cat "$onedarkish_iterm")"
    fi
    defaults write -app iTerm QuitWhenAllWindowsClosed -bool true
fi

# Skim (PDF viewer)
if [ -d "/Applications/Skim.app/" ]; then
    # Auto reload files
    defaults write -app Skim SKAutoReloadFileUpdate -boolean true
    # Synctex (with neovim)
    defaults write -app Skim SKTeXEditorPreset "Custom"
    defaults write -app Skim SKTeXEditorCommand  "nvr"
    defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line|foldo!\'\' %file"
fi

# Install ranger plugins and scope.sh executable
if type "ranger" > /dev/null 2>&1; then
    git clone https://github.com/alexanderjeurissen/ranger_devicons
    (
        cd ranger_devicons || exit
        make install
    )
    rm -rf ranger_devicons
    ranger --copy-config=scope
fi
