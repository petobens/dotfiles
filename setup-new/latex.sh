#!/usr/bin/env bash

# Note: to uninstall basictex (in order to update texlive) remove with `rm -rf`
# the following directories (on Unix): '/usr/local/texlive/', '/Library/TeX/'
# and '/Library/texlive'. Then (at least on Mac) run
# `brew cask reinstall basictex`)

# Define path for initial install (which won't read env variable)
TLMGR_PATH="/usr/local/texlive/2024/bin/x86_64-linux"
PATH="$PATH:$TLMGR_PATH"

# Install texlive
if ! type "tlmgr" > /dev/null 2>&1; then
    wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar xvzf install-tl-unx.tar.gz
    (
        builtin cd install-tl-*/ || exit
        sudo ./install-tl
    )
    rm -rf install-tl-*/
fi

# Install mybibformat style
echo -e "\\033[1;34m--> Installing mybibformat biblatex style...\\033[0m"
if [[ "$OSTYPE" == 'darwin'* ]]; then
    rm -rf ~/Library/texmf
    mkdir -p ~/Library/texmf
    git clone https://github.com/petobens/mybibformat ~/Library/texmf
else
    rm -rf ~/texmf
    mkdir -p ~/texmf
    git clone https://github.com/petobens/mybibformat ~/texmf
fi

# Define tlmgr binary
tlmgr_bin=$TLMGR_PATH/tlmgr

# Update tlmgr and all packages
sudo $tlmgr_bin update --self
sudo $tlmgr_bin update all

# Install texdoc and enable automatic build of documentation
tlmgr_install="sudo $tlmgr_bin install"
$tlmgr_install texdoc
sudo $tlmgr_bin option docfiles 1

# Install arara (needs java)
$tlmgr_install arara

# Install additional binaries: linter, word counter, fonts and biber
$tlmgr_install biber
$tlmgr_install chktex
$tlmgr_install collection-fontsrecommended
$tlmgr_install texcount

# Install additional latex packages
$tlmgr_install biblatex
$tlmgr_install changepage
$tlmgr_install cleveref
$tlmgr_install csquotes
$tlmgr_install emptypage
$tlmgr_install enumitem
$tlmgr_install environ
$tlmgr_install etoolbox
$tlmgr_install floatrow
$tlmgr_install fontawesome
$tlmgr_install footmisc
$tlmgr_install framed
$tlmgr_install fvextra
$tlmgr_install ifmtarg
$tlmgr_install ifplatform
$tlmgr_install imakeidx
$tlmgr_install import
$tlmgr_install lipsum
$tlmgr_install logreq
$tlmgr_install mdwtools
$tlmgr_install minted
$tlmgr_install moderncv
$tlmgr_install multirow
$tlmgr_install newfloat
$tlmgr_install parskip
$tlmgr_install pdfpages
$tlmgr_install pgfplots
$tlmgr_install silence
$tlmgr_install siunitx
$tlmgr_install soul
$tlmgr_install spreadtab
$tlmgr_install standalone
$tlmgr_install tcolorbox
$tlmgr_install titlesec
$tlmgr_install todonotes
$tlmgr_install trimspaces
$tlmgr_install wrapfig
$tlmgr_install xpatch
$tlmgr_install xstring

# Linux specific (i.e not included in basic texlive installation)
if [ "$OSTYPE" == 'linux-gnu' ]; then
    $tlmgr_install algorithm2e
    $tlmgr_install algorithmicx
    $tlmgr_install beamer
    $tlmgr_install bitset
    $tlmgr_install blkarray
    $tlmgr_install booktabs
    $tlmgr_install breqn
    $tlmgr_install caption
    $tlmgr_install catchfile
    $tlmgr_install changelog
    $tlmgr_install embedfile
    $tlmgr_install fancyvrb
    $tlmgr_install float
    $tlmgr_install ifoddpage
    $tlmgr_install infwarerr
    $tlmgr_install jknapltx
    $tlmgr_install l3backend
    $tlmgr_install l3kernel
    $tlmgr_install l3packages
    $tlmgr_install letltxmacro
    $tlmgr_install lineno
    $tlmgr_install listings
    $tlmgr_install mathabx
    $tlmgr_install mathtools
    $tlmgr_install microtype
    $tlmgr_install optidef
    $tlmgr_install pdfescape
    $tlmgr_install pdflscape
    $tlmgr_install pdftexcmds
    $tlmgr_install relsize
    $tlmgr_install sansmath
    $tlmgr_install setspace
    $tlmgr_install translations
    $tlmgr_install translator
    $tlmgr_install ulem
    $tlmgr_install upquote
    $tlmgr_install xcolor
    $tlmgr_install xifthen
    $tlmgr_install xkeyval
fi

# Update all recently installed packages
sudo $tlmgr_bin update all
