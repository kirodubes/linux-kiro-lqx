# linux-kiro-lqx Setup Summary

## What This Is

A custom Arch Linux kernel package built exclusively for this machine.

**Date created**: 2026-05-15
**Based on**: Vanilla Linux 7.0.7 + Liquorix lqx1 patch
**Scheduler**: PDS (Project-C alternative scheduler, part of the lqx patchset)
**Use case**: Low-latency desktop — single fixed profile, no presets

---

## Files

| File                | Purpose                                                    |
|---------------------|------------------------------------------------------------|
| `PKGBUILD`          | Arch build script                                          |
| `config`            | Liquorix `config-arch-64`, full x86-64 config              |
| `v7.0.7-lqx1.patch` | Liquorix zen patch applied to vanilla kernel               |
| `build-kernel.sh`   | Build wrapper — handles modprobed-db, checksums, archiving |
| `clean.sh`          | Cleans build artifacts                                     |
| `up.sh`             | Git stage + status helper                                  |

---

## Fixed Configuration

```
Scheduler:     PDS (Project-C)
Optimization:  -O3 (GCC)
Tick Rate:     1000Hz
Preemption:    Full
THP:           madvise
CPU:           Native (-march=native, always)
Localmod:      Always (modprobed-db required)
TCP:           BBR
LTO:           None (default; optional thin/full)
```

---

## Building

### Prerequisite

```bash
sudo pacman -S base-devel
yay -S modprobed-db
```

### Build

```bash
cd /home/erik/KIRO/linux-kiro-lqx
./build-kernel.sh
```

Expected results:
- Build time: 30–60 minutes (30–50% faster with modprobed-db)
- Packages: `linux-kiro-lqx-7.0.7-1-x86_64.pkg.tar.zst` + headers
- Archived automatically into `kernels/<timestamp>/`

### After Installation

```bash
uname -r                                    # expect: 7.0.7-kiro-lqx
zcat /proc/config.gz | grep CONFIG_SCHED_PDS
zcat /proc/config.gz | grep CONFIG_HZ=
cat /sys/kernel/mm/transparent_hugepage/enabled   # expect: madvise
```

---

## Key Differences from linux-kiro

| Feature     | linux-kiro                  | linux-kiro-lqx              |
|-------------|-----------------------------|-----------------------------|
| Source      | CachyOS pre-patched tarball | Vanilla kernel + lqx patch  |
| Scheduler   | BORE                        | PDS (Project-C)             |
| Config base | CachyOS config              | Liquorix config-arch-64     |
| Presets     | Gaming / Desktop            | None (single fixed profile) |
| THP         | always                      | madvise                     |

---

## Troubleshooting

**Build fails — missing dependencies**
```bash
makepkg --syncdeps -si --skippgpcheck
```

**modprobed-db not found**
```bash
yay -S modprobed-db
modprobed-db store
```

**Kernel doesn't boot**
- Verify bootloader config (grub/refind/systemd-boot)
- Boot into stock Arch kernel to isolate the issue

---

**Status**: Initial setup. PKGBUILD at 7.0.7-lqx1, pkgrel 1.
**Maintainer**: Erik Dubois
