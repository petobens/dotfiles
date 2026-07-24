#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() {
	printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Complete Microsoft's browser authorization on the first run
section 'Synchronizing OneDrive'
onedrive --synchronize
systemctl --user enable --now onedrive

section 'Refreshing configuration symlinks'
"$script_dir/symlinks.sh"
