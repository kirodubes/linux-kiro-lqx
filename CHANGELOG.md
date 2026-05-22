# Changelog — linux-kiro-lqx

## 2026.05.22

### What Changed
`build-kernel.sh` now compares the local `config` against the upstream Liquorix `config-arch-64` on every build invocation and writes a per-build drift report to a new `CONFIG_DRIFT.md`. Prevents silent override of upstream config changes by our pinned local copy — the original concern from the backlog.

### Technical Details
- Runs unconditionally per build (not just on version bump): a single ~250 KB curl from `damentz/liquorix-package/${_cur_major}/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64`. If GitHub is unreachable, prints a warning and continues — drift report is best-effort, never blocks the build.
- Inline Python helper parses both files into `key → value` dicts (treating `# CONFIG_X is not set` as `=n` for comparability) and classifies into three buckets: **A. overrides** (upstream changed, we differ), **B. added by Liquorix** (only upstream), **C. only in our config** (only local).
- Output: dated section prepended to `CONFIG_DRIFT.md` (file auto-created with explanatory front-matter on first run, newest section first — same prepend pattern as `RELEASE_NOTES.md`).
- Tables follow the HQ md-table-alignment convention (cells padded with trailing spaces so pipes line up in raw source).
- Baseline run on `7.0.9-lqx1` flagged the four intentional Erik divergences (KVM_AMD=n, KVM_AMD_SEV=n, ANDROID_BINDER_IPC_RUST=n, SECURITY_LANDLOCK=n) plus one related new upstream addition (`CONFIG_ANDROID_BINDER_DEVICES`). `0 only-local` confirms our config is a clean subset.
- Re-reads `_minor`/`_lqxrel` from PKGBUILD after the version-check block so the report shows the just-updated version, not the pre-bump one.

### Files Modified
- [build-kernel.sh](./build-kernel.sh) — new drift-report block between version-check and clean stages
- [CONFIG_DRIFT.md](./CONFIG_DRIFT.md) — new file (baseline section auto-generated)
- [TODO.md](./TODO.md) — backlog item closed
- [CHANGELOG.md](./CHANGELOG.md) — this entry

## 2026.05.20

### What Changed
`build-kernel.sh` now auto-detects and downloads newer lqx patch versions from GitHub before building — no more manual patch download, PKGBUILD editing, or old-patch cleanup. Added `liquorix.desktop` as a clickable URL shortcut to liquorix.net.

### Technical Details
- At startup, `build-kernel.sh` reads `_major`/`_minor`/`_lqxrel` from PKGBUILD and queries the GitHub API (`damentz/liquorix-package`, branch `${_major}/master`, path `linux-liquorix/debian/patches/zen/`)
- A `python3 -c` inline script (using env var `CUR_MAJOR` for context) parses the JSON response, finds `.patch` files, extracts version via regex `(\d+\.\d+)\.(\d+)[.\-](lqx\d+)`, and picks the highest matching version
- If newer: downloads the patch via `curl -fL`, updates `_minor`/`_lqxrel`/`pkgrel=1` in PKGBUILD via `sed -i`, removes the old patch file — all before `updpkgsums` runs
- Falls through silently (with a warning) if GitHub is unreachable; won't touch PKGBUILD if already at latest
- Major version bumps (e.g., 7.0 → 7.1) are still manual — they require a different liquorix branch and a new kernel base tarball
- `liquorix.url` (Windows-format) was replaced with `liquorix.desktop` using XDG `Type=Link` — the standard for clickable URL shortcuts on Linux, recognized by Thunar, Nautilus, PCManFM, and other XDG-compliant file managers

### Files Modified
- `build-kernel.sh` (added auto version-check and update block)
- `liquorix.desktop` (new — replaces liquorix.url)
- `liquorix.url` (removed)

## 2026.05.19

### What Changed
Bumped kernel to 7.0.9-lqx1 (upstream released 7.0.9). Cleaned up config: disabled three dead/wrong-arch options flagged by a syscheck audit.

### Technical Details
- Downloaded `v7.0.9-lqx1.patch` from `damentz/liquorix-package` (7.0/master branch); removed old `v7.0.7-lqx1.patch`
- PKGBUILD `_minor` updated from 7 → 9; `pkgrel` stays 1 (new upstream minor resets it)
- `b2sums` recalculated automatically by `updpkgsums` inside `./build-kernel.sh`
- Config changes (all in `config` input file):
  - `CONFIG_KVM_AMD=m` / `CONFIG_KVM_AMD_SEV=y` → disabled (machine is Intel i7-10700K, AMD KVM module is dead weight)
  - `CONFIG_ANDROID_BINDER_IPC_RUST=y` + device string → disabled (no Android containers on this desktop)
  - `CONFIG_SECURITY_LANDLOCK=y` → disabled (compiled-in but not in LSM boot list, so never active — just noise)

### Files Modified
- PKGBUILD (_minor: 7 → 9)
- config (KVM_AMD, Binder, Landlock disabled)
- v7.0.7-lqx1.patch (removed)
- v7.0.9-lqx1.patch (added)

## 2026.05.16

### What Changed
Full documentation suite written and published. PKGBUILD compared with the Chaotic-AUR upstream linux-lqx. Shareable onboarding template created for anyone wanting to build their own custom kernel with Claude.

### Technical Details
- Fetched Chaotic-AUR linux-lqx PKGBUILD from GitLab for comparison
- Key differences documented: our PKGBUILD hardcodes native CPU + mandatory modprobed-db + PDS-only, adds LTO support and sub-packages (nvidia-open, ZFS, r8125, debug), uses ZSTD_CLEVEL=19 and module signing; Chaotic's is generic, scheduler-selectable, pulls patches dynamically from the liquorix-package tarball
- CLAUDE.md updated with Reference links section (Chaotic PKGBUILD URL + Liquorix patch source)
- ONBOARDING.md written as a generic template for anyone starting a custom Arch kernel project; shared via Claude Code onboarding link: https://claude.ai/claude-code/onboard/WWvIE2tARwuU
- GitHub push initially failed: `erikdubois` SSH key not added as collaborator on `kirodubes/linux-kiro-lqx`; resolved by adding collaborator access

### Files Modified
- README.md (new)
- SETUP.md (new)
- QUICKSTART.md (new)
- BUILD_SCRIPT_README.md (new)
- COMPARISON.md (new)
- ONBOARDING.md (new)
- CLAUDE.md (updated — added Reference links section)

## 2026.05.15

### What Changed
Initial creation of the linux-kiro-lqx package: a Liquorix/PDS kernel for Kiro, built exclusively for this machine.

### Technical Details
- Source: vanilla Linux 7.0.7 from kernel.org + Liquorix lqx1 patch (`v7.0.7-lqx1.patch`)
- Scheduler: PDS (Project-C alternative scheduler, included in the lqx patchset)
- Config base: Liquorix `config-arch-64` (Debian-generated, adapted for Arch packaging)
- Always native CPU (`-march=native`), always `localmodconfig` via modprobed-db
- HZ: 1000, preemption: full, tickless: full, TCP default: BBR
- LTO optional (none/thin/full), optional nvidia-open/ZFS/r8125 sub-packages
- Helper scripts: `build-kernel.sh`, `clean.sh`, `up.sh`

### Files Modified
- PKGBUILD (new)
- config (new — from Liquorix config-arch-64)
- v7.0.7-lqx1.patch (new — from damentz/liquorix-package)
- build-kernel.sh (new)
- clean.sh (new)
- up.sh (new)
- .gitignore (new)
- CLAUDE.md (new)
- CHANGELOG.md (new)
