current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"
brew_dir=$(brew --prefix)

# Create makevars compiling options (note: for data.table we need to add the
# `-fopenmp` flag).
# To use clang see:
# http://luisspuerto.net/2018/01/install-r-100-homebrew-edition-with-openblas-openmp-my-version/
# To use gcc:
# https://github.com/Rdatatable/data.table/issues/2409#issuecomment-336811279
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

# Actually install libraries (to install from source use devtools or something
# like: `install.packages("data.table", type = "source",
# repos = "http://rdatatable.github.io/data.table")`)
mkdir -p "$brew_dir/lib/R/site-library"
R --slave --no-save << EOF
packages <- readLines("$parent_dir/r_libraries.txt")
new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) {
    print(paste("Installing the following packages:", paste(new_packages, collapse=", ")))
    install.packages(new_packages)
}
EOF
