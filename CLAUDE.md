# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Custom Arch Linux kernel package (`linux-kiro-lqx`) based on Liquorix/Zen kernel patchset. Built exclusively for this machine (Intel i7-10700K). Uses the PDS (Project-C) alternative scheduler from the Liquorix lqx patch — the key difference from `linux-kiro` which uses BORE.

## Kernel profile (fixed — no presets)

| Setting       | Value              |
|---------------|--------------------|
| Source        | vanilla 7.0.9 + lqx1 patch |
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

# Cleanup build artifacts from repo root (does NOT touch kernels/)
./clean.sh

# Stage + commit + push
./up.sh
```

Build takes 30–60 min. With modprobed-db active: 30–50% faster.

## Architecture

**PKGBUILD** — core build script. Options at the top:
- `_makenconfig` / `_makexconfig` — open config editor before build
- `_use_current` — use running kernel's .config as base
- `_use_llvm_lto` — none/thin/full (default: none)
- `_build_nvidia_open` / `_build_zfs` / `_build_r8125` / `_build_debug` — optional sub-packages

The `b2sums` array at the bottom is owned by `updpkgsums` — never edit it manually.

**config** — Liquorix `config-arch-64`, the *input* config for each build. Regenerated via `localmodconfig` during `prepare()`.

**config-`<ver>`-`<pkgrel>`-kiro-lqx** — auto-saved snapshot of the post-localmodconfig `.config`. This is output, not input; never edit it.

**v7.0.9-lqx1.patch** — the Liquorix zen patch applied to vanilla kernel. Source: `damentz/liquorix-package` on GitHub, branch `7.0/master`.

**build-kernel.sh** — wrapper: auto-checks GitHub for a newer lqx patch (downloads + updates PKGBUILD if found), refreshes modprobed.db, optionally enables nconfig, runs `updpkgsums`, runs `makepkg`, archives `.pkg.tar.zst` files into `kernels/<timestamp>/`.

**setup.sh** — one-time git remote configuration (sets SSH alias `github.com-edu`). Run once per machine, not on every session.

**up.sh** — recurring git add/commit/push cycle. Calls `setup.sh` first if the remote isn't configured yet.

## Updating to a new kernel version

**Minor version bump (`_minor` or `_lqxrel` change):** Fully automatic — just run `./build-kernel.sh`. It queries the GitHub API, downloads the new patch, updates PKGBUILD, resets `pkgrel=1`, and removes the old patch before building.

**Major version bump (`_major` change, e.g. 7.0 → 7.1):** Still manual:
1. Update `_major` in PKGBUILD
2. Download new lqx patch from `linux-liquorix/debian/patches/zen/` on the new branch (e.g. `7.1/master`)
3. Copy to this directory, rename to `v<ver>-<lqxrel>.patch`
4. Run `./build-kernel.sh`

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
uname -r                                    # expect 7.0.9-kiro-lqx
zcat /proc/config.gz | grep CONFIG_SCHED_PDS
zcat /proc/config.gz | grep CONFIG_HZ=
zcat /proc/config.gz | grep CONFIG_PREEMPT=
cat /sys/kernel/mm/transparent_hugepage/enabled
```

## Reference links

- Chaotic-AUR linux-lqx PKGBUILD (upstream reference for comparison): https://gitlab.com/chaotic-aur/pkgbuilds/-/blob/main/linux-lqx/PKGBUILD
- Liquorix patch source: https://github.com/damentz/liquorix-package (branch `7.0/master`, path `linux-liquorix/debian/patches/zen/`)

## Session end

When the user signals work is done for the day:

1. Update CHANGELOG.md
2. Update CLAUDE.md current state / next steps
3. Sync best_practices.md: `cp ~/.claude/best_practices.md /home/erik/KIRO/linux-kiro-lqx/best_practices.md`
4. Stage and commit: `git add CHANGELOG.md CLAUDE.md best_practices.md` then push

## Current state

PKGBUILD at 7.0.9-lqx1, pkgrel 1. Config cleaned up: disabled KVM_AMD, Android Binder (Rust), and Landlock. `build-kernel.sh` now auto-updates lqx patch version from GitHub on each run. Next: run `./build-kernel.sh` to build the 7.0.9 kernel (or a newer version if one has dropped).
