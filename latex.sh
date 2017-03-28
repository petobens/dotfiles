#!/usr/bin/env bash
#===============================================================================
#          File: latex.sh
#        Author: Pedro Ferrari
#       Created: 28 Mar 2017
# Last Modified: 28 Mar 2017
#   Description: Setup latex
#===============================================================================
# Download and install arara (we need java and maven first)
if ! type "java" > /dev/null; then
    brew cask install java
    # Wait until basictex is installed
    until type "java" &> /dev/null; do
        sleep 5
    done
fi
brew install maven

echo "Installing arara..."
git clone https://github.com/cereda/arara
cd ./arara/application/ || exit
mvn assembly:assembly

cd ./target || exit
cat > arara << EOF
#!/usr/bin/env bash

exec java -jar \$0 "\$@"


EOF
cat ./arara-4.0-jar-with-dependencies.jar >> ./arara && chmod +x ./arara
mv ./arara "$(brew --prefix)"/bin/
cd ../../../ || exit
rm -rf arara

# Install mybibformat style
echo "Installing mybibformat biblatex style..."
if [[  "$OSTYPE" == 'darwin'* ]]; then
    mkdir -p ~/Library/texmf
    git clone https://github.com/petobens/mybibformat ~/Library/texmf
else
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

# Install linter, word counter and fonts
sudo tlmgr install texcount
sudo tlmgr install chktex
sudo tlmgr install collection-fontsrecommended

# TODO: Install additional latex packages
