apt_install='sudo apt install'
$apt_install python-pip3
$apt_install python3-venv
$apt_install pyenv
$apt_install ctags
$apt_install fzf
$apt_install fd-find
$apt_install ripgrep
$apt_install rust
cargo install lsd
$apt_install lsd
$apt_install bat
$apt_install neofetch
$apt_install z
$apt_install unzip
$apt_install libcurl4-openssl-dev
$apt_install libssl-dev 
$apt_install libxml2-dev
sudo apt install -o Dpkg::Options::="--force-overwrite" bat ripgrep

sudo mkdir -p /usr/share/z
sudo wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O /usr/share/z/z.sh


# R
sudo apt install dirmngr gnupg apt-transport-https ca-certificates software-properties-common
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
sudo apt install r-base
# Server
sudo apt-get install gdebi-core
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1106-amd64.deb
sudo gdebi rstudio-server-1.4.1106-amd64.deb

# Usage
sudo rstudio-server start

