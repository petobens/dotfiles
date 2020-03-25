#!/usr/bin/env bash

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"

# Ensure lib dir is defined 
export R_LIBS_USER="$HOME/.local/lib/R/site-library"

# Actually install libraries (to install from source use devtools or something
# like: `install.packages("data.table", type = "source",
# repos = "http://rdatatable.github.io/data.table")`)
sudo mkdir -p "$R_LIBS_USER"
sudo chmod -R 777 "$(dirname "$R_LIBS_USER")"
R --slave --no-save << EOF
packages <- readLines("$parent_dir/R/r_libraries.txt")
new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) {
    print(paste("Installing the following packages:", paste(new_packages, collapse=", ")))
    install.packages(new_packages, lib=Sys.getenv("R_LIBS_USER"), repos="http://cran.us.r-project.org")
}
EOF

# Install colorout
git clone https://github.com/jalvesaq/colorout.git
R CMD INSTALL colorout
rm -rf colorout
