# CLAUDE.md

## Project

Custom Arch Linux kernel package (`linux-kiro-lqx`) based on Liquorix/Zen kernel patchset. Built exclusively for this machine (Intel i7-10700K). Uses the PDS (Project-C) alternative scheduler from the Liquorix lqx patch — the key difference from `linux-kiro` which uses BORE.

## Kernel profile (fixed — no presets)

| Setting       | Value              |
|---------------|--------------------|
| Source        | vanilla 7.0.7 + lqx1 patch |
| Scheduler     | PDS (Project-C alt sched) |
| HZ            | 1000               |
| Preemption    | full               |
| Tickless      | full (NO_HZ_FULL)  |
| CPU opt       | native (always)    |
| TCP default   | BBR                |
| THP           | madvise            |
| O3            | yes (in base config) |
| Localmod      | always (modprobed-db required) |

## Build commands

```bash
# Recommended: wrapper handles checksums, nconfig prompt, artifact archiving
./build-kernel.sh

# Direct makepkg
makepkg -si --skippgpcheck

# Cleanup build artifacts
./clean.sh

# Stage + status for git
./up.sh
```

Build takes 30–60 min. With modprobed-db active: 30–50% faster.

## Architecture

**PKGBUILD** — core build script. Options at the top:
- `_makenconfig` / `_makexconfig` — open config editor before build
- `_use_current` — use running kernel's .config as base
- `_use_llvm_lto` — none/thin/full (default: none)
- `_build_nvidia_open` / `_build_zfs` / `_build_r8125` / `_build_debug` — optional sub-packages

**config** — Liquorix `config-arch-64`, full x86-64 config with PDS/1000Hz/BBR already set. Regenerated each build via `localmodconfig`.

**v7.0.7-lqx1.patch** — the Liquorix zen patch applied to vanilla kernel. Source: `damentz/liquorix-package` on GitHub, branch `7.0/master`.

**build-kernel.sh** — simple wrapper: checks modprobed.db, optionally enables nconfig, runs updpkgsums, runs makepkg, archives .pkg.tar.zst files into `kernels/<timestamp>/`.

## Updating to a new kernel version

1. Download new lqx patch from `linux-liquorix/debian/patches/zen/` in the liquorix-package repo
2. Copy to this directory, rename to `v<ver>-<lqxrel>.patch`
3. Update `_minor`, `_lqxrel`, `pkgrel` in PKGBUILD
4. Run `./build-kernel.sh` (updpkgsums will recalculate automatically)

## Differences from linux-kiro

| Feature | linux-kiro | linux-kiro-lqx |
|---------|-----------|----------------|
| Source | CachyOS pre-patched tarball | Vanilla kernel + lqx patch |
| Scheduler | BORE | PDS (Project-C) |
| Config base | CachyOS config | Liquorix config-arch-64 |
| Presets | Gaming / Desktop | None (single profile) |
| THP | always | madvise |

## Post-build verification

```bash
uname -r                                    # expect 7.0.7-kiro-lqx
zcat /proc/config.gz | grep CONFIG_SCHED_PDS
zcat /proc/config.gz | grep CONFIG_HZ=
zcat /proc/config.gz | grep CONFIG_PREEMPT=
cat /sys/kernel/mm/transparent_hugepage/enabled
```

## Reference links

- Chaotic-AUR linux-lqx PKGBUILD (upstream reference for comparison): https://gitlab.com/chaotic-aur/pkgbuilds/-/blob/main/linux-lqx/PKGBUILD
- Liquorix patch source: https://github.com/damentz/liquorix-package (branch `7.0/master`, path `linux-liquorix/debian/patches/zen/`)

## Current state

Initial setup. PKGBUILD at 7.0.7-lqx1, pkgrel 1. Run `./build-kernel.sh` to do first build.
