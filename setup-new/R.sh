current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"
brew_dir=$(brew --prefix)

# Create makevars compiling options (note: for data.table we need to add the
# `-fopenmp` flag). See details in:
# http://luisspuerto.net/2018/01/install-r-100-homebrew-edition-with-openblas-openmp-my-version/
if [[  "$OSTYPE" == 'darwin'* ]]; then
    mkdir -p "$HOME/.R"
    echo "\
# Note: this assumes we installed llvm with \`brew install llvm\`
# Add \`-fopenmp\` to the new two lines to compile certain packages (such as
# data.table)
CC=/usr/local/opt/llvm/bin/clang
CXX=/usr/local/opt/llvm/bin/clang++
# -O3 should be faster than -O2 (default) level optimisation
CFLAGS=-g -O3 -Wall -pedantic -std=gnu99 -mtune=native -pipe
CXXFLAGS=-g -O3 -Wall -pedantic -std=c++11 -mtune=native -pipe
LDFLAGS=-L/usr/local/opt/gettext/lib -L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib
CPPFLAGS=-I/usr/local/opt/gettext/include -I/usr/local/opt/llvm/include" > "$HOME/.R/Makevars"
fi

# Actually install libraries
mkdir -p "$brew_dir/lib/R/site-library"
R --slave --no-save << EOF
packages <- readLines("$parent_dir/r_libraries.txt")
new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) {
    print(paste("Installing the following packages:", paste(new_packages, collapse=", ")))
    install.packages(new_packages)
}
EOF
