#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
current_step=0
total_steps=$(grep -c "^section '" "${BASH_SOURCE[0]}")

declare gpg_private gpg_public netrc pass_repo ssh_config ssh_private ssh_public
declare -a repos

# shellcheck disable=SC1091
source "$script_dir/load_personal.sh"

section() {
    ((current_step += 1))
    printf '\033[1;34m\n-> [%d/%d] %s...\033[0m\n' \
        "$current_step" "$total_steps" "$1"
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# Complete Microsoft's browser authorization on the first run
section 'Synchronizing OneDrive'
onedrive --sync
systemctl --user enable --now onedrive
load_personal
for required_file in \
    "$netrc" \
    "$gpg_private" \
    "$gpg_public" \
    "$ssh_config" \
    "$ssh_private" \
    "$ssh_public"; do
    [[ -f $required_file ]] ||
        die "Missing personal file: $required_file"
done

section 'Linking synchronized files'
"$script_dir/symlinks.sh"

section 'Importing GPG keys'
fingerprint=$(gpg --show-keys --with-colons "$gpg_public" |
    awk -F: '$1 == "fpr" && !found { print $10; found=1 }')
[[ -n $fingerprint ]] || die "No GPG key found in $gpg_public"
gpg --import "$gpg_public"
if ! gpg --list-secret-keys "$fingerprint" > /dev/null 2>&1; then
    gpg --decrypt "$gpg_private" | gpg --import
fi

section 'Restoring SSH credentials'
install -d -m700 "$HOME/.ssh"
if [[ ! -e $HOME/.ssh/id_rsa ]]; then
    (
        umask 077
        temporary_key=$(mktemp "$HOME/.ssh/id_rsa.XXXXXX")
        trap 'rm -f -- "$temporary_key"' EXIT
        gpg --output "$temporary_key" --decrypt "$ssh_private"
        mv -- "$temporary_key" "$HOME/.ssh/id_rsa"
        trap - EXIT
    )
fi

section 'Restoring password store'
password_store_dir="$HOME/.password-store"
if [[ ! -d $password_store_dir/.git ]]; then
    [[ ! -e $password_store_dir ]] ||
        die "$password_store_dir exists but is not a Git repository"
    gopass clone "$pass_repo"
fi

section 'Cloning private repositories'
repos_dir="$HOME/git-repos/private"
mkdir -p "$repos_dir"
for repository in "${repos[@]}"; do
    name=${repository##*/}
    name=${name%.git}
    [[ $name =~ ^[a-zA-Z0-9._-]+$ ]] ||
        die "Invalid repository name: $repository"
    target="$repos_dir/$name"
    if [[ ! -d $target/.git ]]; then
        [[ ! -e $target ]] ||
            die "$target exists but is not a Git repository"
        git clone "$repository" "$target"
    fi
done

section 'Refreshing configuration symlinks'
"$script_dir/symlinks.sh"
