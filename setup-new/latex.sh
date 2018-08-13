#!/usr/bin/env bash

# Note: to uninstall basictex (in order to update texlive) remove with `rm -rf`
# the following directories (on Unix): '/usr/local/texlive/', '/Library/TeX/'
# and '/Library/texlive'. Then (at least on Mac) run
# `brew cask reinstall basictex`)

# Install mybibformat style
echo "Installing mybibformat biblatex style..."
if [[  "$OSTYPE" == 'darwin'* ]]; then
    rm -rf ~/Library/texmf
    mkdir -p ~/Library/texmf
    git clone https://github.com/petobens/mybibformat ~/Library/texmf
else
    rm -rf ~/texmf
    mkdir -p ~/texmf
    git clone https://github.com/petobens/mybibformat ~/texmf
fi

# Update tlmgr and all packages
sudo tlmgr update --self
sudo tlmgr update all

# Install texdoc and enable automatic build of documentation
sudo tlmgr install texdoc
sudo tlmgr option docfiles 1
sudo tlmgr install --reinstall "$(tlmgr list --only-installed | sed -e 's/^i //' -e 's/:.*$//')"

# Install arara (needs java)
read -p "Do you want to install arara (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! java -version >/dev/null 2>&1;  then
        if [[  "$OSTYPE" == 'darwin'* ]]; then
            brew cask install java
        else
            yay jdk
        fi
    fi
    sudo tlmgr install arara
fi

# Install additional binaries: linter, word counter, fonts and biber
sudo tlmgr install biber
sudo tlmgr install chktex
sudo tlmgr install collection-fontsrecommended
sudo tlmgr install texcount

# Install additional latex packages
sudo tlmgr install biblatex
sudo tlmgr install cleveref
sudo tlmgr install csquotes
sudo tlmgr install emptypage
sudo tlmgr install enumitem
sudo tlmgr install environ
sudo tlmgr install etoolbox
sudo tlmgr install floatrow
sudo tlmgr install fontawesome
sudo tlmgr install footmisc
sudo tlmgr install framed
sudo tlmgr install fvextra
sudo tlmgr install ifplatform
sudo tlmgr install imakeidx
sudo tlmgr install import
sudo tlmgr install lipsum
sudo tlmgr install logreq
sudo tlmgr install minted
sudo tlmgr install moderncv
sudo tlmgr install multirow
sudo tlmgr install pgfplots
sudo tlmgr install silence
sudo tlmgr install siunitx
sudo tlmgr install spreadtab
sudo tlmgr install standalone
sudo tlmgr install tcolorbox
sudo tlmgr install titlesec
sudo tlmgr install trimspaces
sudo tlmgr install wrapfig
sudo tlmgr install xpatch
sudo tlmgr install xstring

# Linux specific (i.e not included in basic texlive installation)
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    sudo tlmgr install beamer
    sudo tlmgr install booktabs
    sudo tlmgr install breqn
    sudo tlmgr install caption
    sudo tlmgr install fancyvrb
    sudo tlmgr install float
    sudo tlmgr install jknapltx
    sudo tlmgr install l3kernel
    sudo tlmgr install l3packages
    sudo tlmgr install lineno
    sudo tlmgr install mathtools
    sudo tlmgr install microtype
    sudo tlmgr install setspace
    sudo tlmgr install translator
    sudo tlmgr install ulem
    sudo tlmgr install upquote
    sudo tlmgr install xcolor
    sudo tlmgr install xkeyval
fi

# Update all recently installed packages
sudo tlmgr update all
