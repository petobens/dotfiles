#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Complete Microsoft's browser authorization on the first run
onedrive --synchronize
systemctl --user enable --now onedrive
"$script_dir/symlinks.sh"
