fish_add_path \
    "$HOME/bin" \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.npm-global/bin"

set -l texlive_bins /usr/local/texlive/*/bin/x86_64-linux
test (count $texlive_bins) -eq 0; or fish_add_path "$texlive_bins[-1]"
