#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
rm -rf src/ pkg/ linux-*.tar.xz *.pkg.tar.zst
echo "Cleaned build artifacts."
