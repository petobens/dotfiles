#!/usr/bin/env bash
set -euo pipefail

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Verify the system dependencies needed by the native installer
for command in curl git perl tar; do
    command -v "$command" > /dev/null || {
        echo "Missing $command. Install the system packages first." >&2
        exit 1
    }
done

section 'Installing the arara Java runtime'
sudo pacman -S --needed --noconfirm jre21-openjdk-headless

# Reuse the newest native TeX Live installation when available
texlive_root=/usr/local/texlive
tlmgr=$(find "$texlive_root" -path '*/bin/x86_64-linux/tlmgr' -type f 2> /dev/null |
    sort -V | tail -1)

if [[ -z $tlmgr ]]; then
    section 'Installing TeX Live'
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    archive="$tmp/install-tl-unx.tar.gz"
    curl --fail --location --output "$archive" \
        https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar -xzf "$archive" -C "$tmp"
    installer=("$tmp"/install-tl-*/install-tl)
    sudo perl "${installer[0]}" --no-interaction --scheme=basic
    tlmgr=$(find "$texlive_root" -path '*/bin/x86_64-linux/tlmgr' -type f |
        sort -V | tail -1)
fi

[[ -x $tlmgr ]] || {
    echo 'TeX Live installation did not produce tlmgr.' >&2
    exit 1
}

# Keep the requested TeX packages explicit and reproducible
packages=(
    algorithm2e
    algorithmicx
    arara
    beamer
    biber
    biblatex
    bitset
    blkarray
    booktabs
    breqn
    caption
    catchfile
    changelog
    changepage
    chktex
    cleveref
    collection-basic
    collection-fontsrecommended
    collection-langenglish
    collection-langspanish
    collection-latex
    csquotes
    embedfile
    emptypage
    enumitem
    environ
    etoolbox
    fancyvrb
    float
    floatrow
    fontawesome
    footmisc
    framed
    fvextra
    ifmtarg
    ifoddpage
    ifplatform
    imakeidx
    import
    infwarerr
    jknapltx
    l3backend
    l3kernel
    l3packages
    letltxmacro
    lineno
    lipsum
    listings
    logreq
    mathabx
    mathtools
    mdwtools
    microtype
    minted
    moderncv
    multirow
    newfloat
    optidef
    parskip
    pdfescape
    pdflscape
    pdfpages
    pdftexcmds
    pgfplots
    relsize
    sansmath
    setspace
    silence
    siunitx
    soul
    spreadtab
    standalone
    tcolorbox
    texcount
    texdoc
    titlesec
    todonotes
    translations
    translator
    trimspaces
    ulem
    upquote
    wrapfig
    xcolor
    xifthen
    xkeyval
    xpatch
    xstring
)

section 'Installing TeX Live packages'
sudo "$tlmgr" update --self
sudo "$tlmgr" option docfiles 1
sudo "$tlmgr" install "${packages[@]}"
sudo "$tlmgr" update --all
sudo "$tlmgr" path add

if [[ ! -d $HOME/texmf ]]; then
    section 'Installing personal BibLaTeX style'
    git clone https://github.com/petobens/mybibformat "$HOME/texmf"
fi
