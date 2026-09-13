#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
current_step=0
full_sync=false
dry_run=false

declare gpg_private gpg_public netrc onedrive pass_repo personal_config
declare personal_directory required_directory ssh_config ssh_private ssh_public
declare -A synchronized_directories
declare -a repos

# shellcheck disable=SC1091
source "$script_dir/load_personal.sh"

section() {
    ((current_step += 1))
    printf '\033[1;34m==> [%d/%d] %s...\033[0m\n' \
        "$current_step" "$total_steps" "$1"
}

die() {
    printf '\033[1;31mError: %s\033[0m\n' "$1" >&2
    exit 1
}

run_component() {
    printf '\n'
    "$@"
}

usage() {
    cat << EOF
usage: $0 [--full-sync] [--dry-run]

  --full-sync  Enable and start full OneDrive synchronization
  --dry-run    Preview the personal directory download and exit; overrides --full-sync
               Authorizes OneDrive first if needed, saving login data locally
EOF
}

for arg in "$@"; do
    case $arg in
        --full-sync) full_sync=true ;;
        --dry-run) dry_run=true ;;
        -h | --help)
            usage
            exit
            ;;
        *)
            printf 'unknown option: %s\n' "$arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

personal_directory=$(dirname "${personal_config#"$onedrive"/}")
if $dry_run; then
    # OneDrive cannot save first-time authorization during a dry-run
    if [[ ! -s ${XDG_CONFIG_HOME:-$HOME/.config}/onedrive/refresh_token ]]; then
        printf 'Authorizing OneDrive before the download preview...\n'
        onedrive
    fi
    exec onedrive --sync --download-only \
        --single-directory "$personal_directory" --dry-run
fi

total_steps=$(grep -Ec "^[[:space:]]*section '" "${BASH_SOURCE[0]}")
if ! $full_sync; then
    ((total_steps -= 1))
fi

printf '\033[1;32m:: Starting personal setup\033[0m\n'

# Authenticate and fetch the personal configuration without a full sync
# Download-only mode prevents an incomplete local tree from changing OneDrive
section 'Loading personal configuration'
onedrive --sync --download-only --single-directory "$personal_directory"
load_personal
synchronized_directories[$personal_directory]=1

# Download each directory needed to restore credentials once
section 'Downloading required personal files'
for required_file in \
    "$netrc" \
    "$gpg_private" \
    "$gpg_public" \
    "$ssh_config" \
    "$ssh_private" \
    "$ssh_public"; do
    required_directory=$(dirname "${required_file#"$onedrive"/}")
    if [[ ! -v synchronized_directories[$required_directory] ]]; then
        onedrive --sync --download-only \
            --single-directory "$required_directory"
        synchronized_directories[$required_directory]=1
    fi
    [[ -f $required_file ]] ||
        die "Missing personal file: $required_file"
done

if $full_sync; then
    section 'Starting full OneDrive synchronization'
    systemctl --user enable --now onedrive
fi

section 'Linking synchronized files'
run_component "$script_dir/symlinks.sh"

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
        gpg --yes --output "$temporary_key" --decrypt "$ssh_private"
        mv -- "$temporary_key" "$HOME/.ssh/id_rsa"
        trap - EXIT
    )
fi

section 'Restoring password store'
password_store_dir="$HOME/.password-store"
if [[ ! -d $password_store_dir/.git ]]; then
    if [[ -e $password_store_dir ]]; then
        rmdir -- "$password_store_dir" ||
            die "$password_store_dir exists but is not an empty directory or Git repository"
    fi
    gopass clone --path "$password_store_dir" "$pass_repo"
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
run_component "$script_dir/symlinks.sh"
