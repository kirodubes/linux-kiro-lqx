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

            # Prepend a new section to RELEASE_NOTES.md
            _release_notes="$SCRIPT_DIR/RELEASE_NOTES.md"
            if [[ ! -f "$_release_notes" ]]; then
                cat > "$_release_notes" <<'RN_EOF'
# Release Notes — linux-kiro-lqx

One section per kernel version bump. Newest at the top. New sections are auto-prepended by `build-kernel.sh` when it detects a new lqx patch on GitHub.

RN_EOF
            fi

            _new_section="## ${_cur_major}.${_new_minor}-${_new_lqxrel} ($(date +%Y-%m-%d))

Bumped from ${_cur_major}.${_cur_minor}-${_cur_lqxrel} → ${_cur_major}.${_new_minor}-${_new_lqxrel}.

- **Patch source**: ${_new_url}
- **Scheduler**: PDS (unchanged)
- **lqx changelog**: https://github.com/damentz/liquorix-package/commits/${_cur_major}/master
"

            RELEASE_NOTES_PATH="$_release_notes" NEW_SECTION="$_new_section" python3 - <<'PY'
import os, pathlib
path = pathlib.Path(os.environ["RELEASE_NOTES_PATH"])
new_section = os.environ["NEW_SECTION"]
lines = path.read_text().splitlines(keepends=True)
insert_at = next((i for i, l in enumerate(lines) if l.startswith("## ")), len(lines))
out = "".join(lines[:insert_at]) + new_section + "\n" + "".join(lines[insert_at:])
path.write_text(out)
PY
            echo "RELEASE_NOTES.md updated with ${_cur_major}.${_new_minor}-${_new_lqxrel} section"
        else
            echo "Already at latest: ${_cur_major}.${_cur_minor}-${_cur_lqxrel}"
        fi
    else
        echo "Warning: Could not find versioned patch in GitHub response — skipping version check"
    fi
fi

# ── Liquorix config-arch-64 drift report ────────────────────────────────────

# Re-read minor/lqxrel from PKGBUILD so we report against the just-updated values
# (the auto-update block above may have bumped them after the initial read).
_drift_minor=$(grep -Po '^_minor=\K\S+' PKGBUILD)
_drift_lqxrel=$(grep -Po '^_lqxrel=\K\S+' PKGBUILD)
_drift_ver="${_cur_major}.${_drift_minor}-${_drift_lqxrel}"
_drift_url="https://raw.githubusercontent.com/damentz/liquorix-package/${_cur_major}/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
_drift_tmp=$(mktemp)

echo "Fetching upstream config-arch-64 for drift report..."
if ! curl -sfL --max-time 30 "$_drift_url" -o "$_drift_tmp"; then
    echo "Warning: Could not fetch upstream config-arch-64 — skipping drift report"
    rm -f "$_drift_tmp"
else
    _drift_file="$SCRIPT_DIR/CONFIG_DRIFT.md"
    _drift_section=$(LOCAL="$SCRIPT_DIR/config" UPSTREAM="$_drift_tmp" \
                     URL="$_drift_url" VER="$_drift_ver" \
                     python3 - <<'PY'
import os, datetime

def parse(path):
    out = {}
    with open(path) as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            if s.startswith("# CONFIG_") and s.endswith(" is not set"):
                key = s[2:].rsplit(" is not set", 1)[0]
                out[key] = "n"
            elif s.startswith("CONFIG_") and "=" in s:
                key, _, val = s.partition("=")
                out[key] = val
    return out

local = parse(os.environ["LOCAL"])
upstream = parse(os.environ["UPSTREAM"])

overrides, added, only_local = [], [], []
for k in sorted(set(local) | set(upstream)):
    lv, uv = local.get(k), upstream.get(k)
    if lv is None:
        added.append((k, uv))
    elif uv is None:
        only_local.append((k, lv))
    elif lv != uv:
        overrides.append((k, uv, lv))

def md_table(rows, headers):
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    pad_row = lambda r: "| " + " | ".join(c.ljust(w) for c, w in zip(r, widths)) + " |"
    sep = "|" + "|".join("-" * (w + 2) for w in widths) + "|"
    return "\n".join([pad_row(headers), sep] + [pad_row(r) for r in rows])

date = datetime.date.today().isoformat()
ver = os.environ["VER"]
url = os.environ["URL"]

lines = [
    f"## {date} — {ver}",
    "",
    f"- Upstream: <{url}>",
    f"- Counts: **{len(overrides)} overrides** · {len(added)} new upstream · {len(only_local)} only-local",
    "",
]
if overrides:
    lines += [
        "### A. Options we override (upstream changed value, our config keeps different)",
        "",
        md_table(overrides, ["Option", "Upstream", "Local"]),
        "",
    ]
if added:
    lines += ["### B. Added by Liquorix (not in our config)", ""]
    lines += [f"- `{k}={v}`" for k, v in added]
    lines.append("")
if only_local:
    lines += ["### C. Only in our config (Liquorix does not set)", ""]
    lines += [f"- `{k}={v}`" for k, v in only_local]
    lines.append("")
if not (overrides or added or only_local):
    lines += ["No drift — local config matches upstream byte-for-byte.", ""]

print("\n".join(lines))
PY
)

    if [[ ! -f "$_drift_file" ]]; then
        cat > "$_drift_file" <<'DRIFT_EOF'
# Liquorix Config Drift — linux-kiro-lqx

Per-build comparison of local [`config`](./config) vs upstream `linux-liquorix/debian/config/kernelarch-x86/config-arch-64` on the matching `<major>/master` branch. Newest section first. Auto-prepended by [`build-kernel.sh`](./build-kernel.sh).

Three buckets:

- **A. Overrides** — options where upstream changed value but our pinned config keeps a different one. **These matter most**: a Liquorix upstream change is silently being undone by our config.
- **B. Added by Liquorix** — options upstream now sets that we don't have at all (likely new since our last sync).
- **C. Only in our config** — options we set that upstream doesn't (intentional Kiro customizations, or stale entries to prune).

DRIFT_EOF
    fi

    DRIFT_PATH="$_drift_file" NEW_SECTION="$_drift_section" python3 - <<'PY'
import os, pathlib
path = pathlib.Path(os.environ["DRIFT_PATH"])
new = os.environ["NEW_SECTION"]
lines = path.read_text().splitlines(keepends=True)
insert_at = next((i for i, l in enumerate(lines) if l.startswith("## ")), len(lines))
out = "".join(lines[:insert_at]) + new + "\n" + "".join(lines[insert_at:])
path.write_text(out)
PY

    _drift_summary=$(awk -F'Counts: ' '/Counts:/ {gsub(/\*\*/, "", $2); print $2; exit}' <<< "$_drift_section")
    echo "CONFIG_DRIFT.md updated for ${_drift_ver}: ${_drift_summary}"
    rm -f "$_drift_tmp"
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
_build_start=$SECONDS
makepkg -s --skippgpcheck
_build_seconds=$((SECONDS - _build_start))

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

# ── Build stats ──────────────────────────────────────────────────────────────

_hist_pkgver=$(grep -Po 'pkgver=\K[0-9.]+' PKGBUILD)
_hist_pkgrel=$(grep -Po 'pkgrel=\K[0-9]+' PKGBUILD)
_hist_lqxrel=$(grep -Po '_lqxrel=\K\S+' PKGBUILD)
_hist_snap="$SCRIPT_DIR/config-${_hist_pkgver}-${_hist_pkgrel}-kiro-lqx"
if [[ -f "$_hist_snap" ]]; then
    _hist_modules=$(grep -c '^CONFIG_[A-Z0-9_]*=m$' "$_hist_snap" || echo 0)
else
    _hist_modules=0
fi
_hist_size_bytes=$(stat -c%s "$DEST"/*.pkg.tar.zst 2>/dev/null | awk '{s+=$1} END {print s+0}')
_hist_size_mb=$(awk "BEGIN {printf \"%.1f\", ${_hist_size_bytes}/1024/1024}")
_hist_duration=$(printf '%dm%02ds' $((_build_seconds/60)) $((_build_seconds%60)))

cat > "$DEST/build-info.md" <<EOF
# Build info

- Date     : $(date)
- pkgver   : ${_hist_pkgver}
- pkgrel   : ${_hist_pkgrel}
- lqxrel   : ${_hist_lqxrel}
- Duration : ${_hist_duration} (${_build_seconds}s)
- Modules  : ${_hist_modules}
- Size     : ${_hist_size_mb} MB
- CPU      : native
- Sched    : PDS (Liquorix)
- HZ       : 1000
- Preempt  : full
EOF

# ── Append to build-history.csv ──────────────────────────────────────────────

HISTORY_CSV="$KERNELS_DIR/build-history.csv"
if [[ ! -f "$HISTORY_CSV" ]]; then
    echo "timestamp,pkgver,pkgrel,lqxrel,build_seconds,modules,size_mb" > "$HISTORY_CSV"
fi
echo "$(date -Iseconds),${_hist_pkgver},${_hist_pkgrel},${_hist_lqxrel},${_build_seconds},${_hist_modules},${_hist_size_mb}" >> "$HISTORY_CSV"
echo "build-history.csv: appended ${_hist_pkgver}-${_hist_pkgrel} (${_hist_duration}, ${_hist_modules} modules, ${_hist_size_mb} MB)"

echo ""
echo "Packages stored in: $DEST"
ls -lh "$DEST"
