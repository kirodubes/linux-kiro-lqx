#!/bin/bash
set -euo pipefail

# Build wrapper for linux-kiro-lqx.
# Always builds for this machine: native CPU, modprobed-db, PDS scheduler.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODPROBED_DB="$HOME/.config/modprobed.db"
KERNELS_DIR="$SCRIPT_DIR/kernels"

cd "$SCRIPT_DIR"

# ── Version check and auto-update ────────────────────────────────────────────

_cur_major=$(grep -Po '^_major=\K\S+' PKGBUILD)
_cur_minor=$(grep -Po '^_minor=\K\S+' PKGBUILD)
_cur_lqxrel=$(grep -Po '^_lqxrel=\K\S+' PKGBUILD)

echo "Current version: ${_cur_major}.${_cur_minor}-${_cur_lqxrel}"
echo "Checking for newer lqx patch on GitHub..."

_api_url="https://api.github.com/repos/damentz/liquorix-package/contents/linux-liquorix/debian/patches/zen?ref=${_cur_major}/master"
_api_json=$(curl -sf --max-time 10 "$_api_url" 2>/dev/null || true)

if [[ -z "$_api_json" ]]; then
    echo "Warning: Could not reach GitHub API — skipping version check"
else
    _patch_entry=$(echo "$_api_json" | CUR_MAJOR="$_cur_major" python3 -c '
import json, sys, re, os
cur_major = os.environ["CUR_MAJOR"]
data = json.loads(sys.stdin.read())
patches = [e for e in data if isinstance(e, dict) and e.get("name", "").endswith(".patch")]
if not patches:
    sys.exit(0)
def ver_key(e):
    m = re.search(r"(\d+\.\d+)\.(\d+)[.\-](lqx\d+)", e["name"])
    if m and m.group(1) == cur_major:
        return (int(m.group(2)), m.group(3))
    return (-1, "")
best = max(patches, key=ver_key)
m = re.search(r"(\d+\.\d+)\.(\d+)[.\-](lqx\d+)", best["name"])
if m and m.group(1) == cur_major:
    print(m.group(2), m.group(3), best["download_url"])
' || true)

    if [[ -n "$_patch_entry" ]]; then
        _new_minor=$(awk '{print $1}' <<< "$_patch_entry")
        _new_lqxrel=$(awk '{print $2}' <<< "$_patch_entry")
        _new_url=$(awk '{print $3}' <<< "$_patch_entry")

        if [[ "$_new_minor" != "$_cur_minor" || "$_new_lqxrel" != "$_cur_lqxrel" ]]; then
            echo "Upgrading: ${_cur_major}.${_cur_minor}-${_cur_lqxrel} → ${_cur_major}.${_new_minor}-${_new_lqxrel}"
            _local_patch="v${_cur_major}.${_new_minor}-${_new_lqxrel}.patch"
            echo "Downloading patch..."
            curl -fL --max-time 120 -o "$_local_patch" "$_new_url"

            sed -i "s/^_minor=.*/_minor=${_new_minor}/" PKGBUILD
            sed -i "s/^_lqxrel=.*/_lqxrel=${_new_lqxrel}/" PKGBUILD
            sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

            _old_patch="v${_cur_major}.${_cur_minor}-${_cur_lqxrel}.patch"
            if [[ "$_old_patch" != "$_local_patch" && -f "$_old_patch" ]]; then
                rm "$_old_patch"
                echo "Removed old patch: $_old_patch"
            fi
            echo "PKGBUILD updated to ${_cur_major}.${_new_minor}-${_new_lqxrel}"
        else
            echo "Already at latest: ${_cur_major}.${_cur_minor}-${_cur_lqxrel}"
        fi
    else
        echo "Warning: Could not find versioned patch in GitHub response — skipping version check"
    fi
fi

# ── Clean previous build artifacts ───────────────────────────────────────────

echo "Cleaning src/ and pkg/ from previous build..."
rm -rf "$SCRIPT_DIR/src" "$SCRIPT_DIR/pkg"

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
