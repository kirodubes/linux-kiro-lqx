#!/bin/bash
set -euo pipefail

# Build wrapper for linux-kiro-lqx.
# Always builds for this machine: native CPU, modprobed-db, PDS scheduler.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODPROBED_DB="$HOME/.config/modprobed.db"
KERNELS_DIR="$SCRIPT_DIR/kernels"

cd "$SCRIPT_DIR"

# ── modprobed-db: install if missing, always refresh ─────────────────────────

if ! command -v modprobed-db &>/dev/null; then
    echo "modprobed-db not found — installing from AUR..."
    if command -v paru &>/dev/null; then
        paru -S --noconfirm modprobed-db
    elif command -v yay &>/dev/null; then
        yay -S --noconfirm modprobed-db
    else
        echo "ERROR: No AUR helper found (paru or yay). Install modprobed-db manually."
        exit 1
    fi
fi

echo "Storing currently loaded modules into modprobed.db..."
modprobed-db store

if [[ ! -f "$MODPROBED_DB" ]]; then
    echo "ERROR: modprobed.db still missing after store — something went wrong."
    exit 1
fi

VBOX_MODULES=(vboxdrv vboxnetadp vboxnetflt)
for mod in "${VBOX_MODULES[@]}"; do
    if ! grep -qx "$mod" "$MODPROBED_DB"; then
        echo "$mod" >> "$MODPROBED_DB"
        echo "+ Added missing VirtualBox module: $mod"
    fi
done
sort -u -o "$MODPROBED_DB" "$MODPROBED_DB"

echo "modprobed.db ready: $(wc -l < "$MODPROBED_DB") entries"

# ── Optional nconfig ──────────────────────────────────────────────────────────

answer=""
[[ -t 0 ]] && read -r -p "Open nconfig to tweak kernel options before building? [y/N] " answer || true
if [[ "${answer,,}" == "y" ]]; then
    sed -i 's/^: "${_makenconfig:=no}"$/: "${_makenconfig:=yes}"/' PKGBUILD
    trap 'sed -i "s/^: \"\${_makenconfig:=yes}\"$/: \"\${_makenconfig:=no}\"/" PKGBUILD' EXIT
fi

# ── Update checksums ──────────────────────────────────────────────────────────

echo "Updating checksums..."
updpkgsums

# ── Build ─────────────────────────────────────────────────────────────────────

echo "Starting kernel build..."
makepkg -s --skippgpcheck

# ── Archive packages ──────────────────────────────────────────────────────────

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="$KERNELS_DIR/$TIMESTAMP"
mkdir -p "$DEST"

shopt -s nullglob
packages=("$SCRIPT_DIR"/*.pkg.tar.zst)
shopt -u nullglob

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages found — build may have failed."
    exit 1
fi

for pkg in "${packages[@]}"; do
    mv -v "$pkg" "$DEST/"
done

cat > "$DEST/build-info.md" <<EOF
# Build info

- Date    : $(date)
- pkgver  : $(grep -Po 'pkgver=\K[0-9.]+' PKGBUILD)
- pkgrel  : $(grep -Po 'pkgrel=\K[0-9]+' PKGBUILD)
- lqxrel  : $(grep -Po '_lqxrel=\K\S+' PKGBUILD)
- CPU     : native
- Sched   : PDS (Liquorix)
- HZ      : 1000
- Preempt : full
EOF

echo ""
echo "Packages stored in: $DEST"
ls -lh "$DEST"
