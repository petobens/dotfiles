#!/usr/bin/env bash
# Download and install arara (we need java and maven first)
if ! java -version >/dev/null 2>&1;  then
    if [[  "$OSTYPE" == 'darwin'* ]]; then
        brew cask install java
    else
        sudo apt-get install default-jre
    fi
fi
brew install maven

echo "Installing arara..."
rm -rf "$(brew --prefix)"/lib/arara
rm -rf "$(brew --prefix)"/bin/arara
git clone https://github.com/cereda/arara
cd ./arara/application/ || exit
mvn compile assembly:single

cd ./target || exit
cat > arara << EOF
#!/usr/bin/env bash

exec java -jar \$0 "\$@"


EOF
cat ./arara-4.0-jar-with-dependencies.jar >> ./arara && chmod +x ./arara
cd ../../../ || exit
mv arara/application/target/arara arara/
mkdir "$(brew --prefix)"/lib/arara
mv arara/* "$(brew --prefix)"/lib/arara
ln -s  "$(brew --prefix)"/lib/arara/arara "$(brew --prefix)"/bin/arara
rm -rf arara

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

# Install additional binaries: linter, word counter, fonts and biber
sudo tlmgr install texcount
sudo tlmgr install chktex
sudo tlmgr install collection-fontsrecommended
sudo tlmgr install biber

# Install additional latex packages
sudo tlmgr install amssymb
sudo tlmgr install biblatex
sudo tlmgr install cleveref
sudo tlmgr install csquotes
sudo tlmgr install emptypage
sudo tlmgr install enumitem
sudo tlmgr install environ
sudo tlmgr install etoolbox
sudo tlmgr install floatrow
sudo tlmgr install footmisc
sudo tlmgr install framed
sudo tlmgr install fvextra
sudo tlmgr install ifplatform
sudo tlmgr install imakeidx
sudo tlmgr install lipsum
sudo tlmgr install logreq
sudo tlmgr install minted
sudo tlmgr install multirow
sudo tlmgr install silence
sudo tlmgr install siunitx
sudo tlmgr install spreadtab
sudo tlmgr install tcolorbox
sudo tlmgr install titlesec
sudo tlmgr install trimspaces
sudo tlmgr install xpatch
sudo tlmgr install xstring
sudo tlmgr install wrapfig

# Update all recently installed packages
sudo tlmgr update all
