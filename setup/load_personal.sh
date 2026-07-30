#!/usr/bin/env bash

# personal.json uses OneDrive-relative paths for gpg_private, gpg_public, netrc,
# ssh_config, ssh_private, and ssh_public. pass_repo is a URL and repos is an
# array of URLs.
# shellcheck disable=SC2034
onedrive=${ONEDRIVE_DIR:-"$HOME/OneDrive"}
personal_config=${PERSONAL_CONFIG:-"$onedrive/programming/arch/personal.json"}

load_personal() {
    [[ -r $personal_config ]] || {
        printf 'Missing personal configuration: %s\n' "$personal_config" >&2
        return 1
    }

    gpg_private="$onedrive/$(jq -er '.gpg_private' "$personal_config")"
    gpg_public="$onedrive/$(jq -er '.gpg_public' "$personal_config")"
    netrc="$onedrive/$(jq -er '.netrc' "$personal_config")"
    pass_repo=$(jq -er '.pass_repo' "$personal_config")
    ssh_config="$onedrive/$(jq -er '.ssh_config' "$personal_config")"
    ssh_private="$onedrive/$(jq -er '.ssh_private' "$personal_config")"
    ssh_public="$onedrive/$(jq -er '.ssh_public' "$personal_config")"
    mapfile -t repos < <(jq -er '.repos[]' "$personal_config")
    ((${#repos[@]}))
}
