# linux-kiro-lqx — Quick Start

## What You Have

A single-profile Liquorix/PDS kernel for this machine. No gaming/desktop toggle — one configuration, always the same.

## Build

```bash
cd /home/erik/KIRO/linux-kiro-lqx
./build-kernel.sh
```

The script will:
1. Install `modprobed-db` if missing
2. Store loaded modules (`modprobed-db store`)
3. Ask if you want to open `nconfig` for manual tweaks
4. Update checksums (`updpkgsums`)
5. Build with `makepkg`
6. Move packages to `kernels/<timestamp>/`

Build time: ~40 min on i7-10700K with modprobed-db active.

## Verify After Reboot

```bash
uname -r
# expect: 7.0.7-kiro-lqx

zcat /proc/config.gz | grep CONFIG_SCHED_PDS
# expect: CONFIG_SCHED_PDS=y

zcat /proc/config.gz | grep CONFIG_HZ=
# expect: CONFIG_HZ=1000

zcat /proc/config.gz | grep CONFIG_PREEMPT=
# expect: CONFIG_PREEMPT=y

cat /sys/kernel/mm/transparent_hugepage/enabled
# expect: always [madvise] never
```

## File Structure

```
/home/erik/KIRO/linux-kiro-lqx/
├── build-kernel.sh          <- run this
├── clean.sh                 <- removes build artifacts
├── up.sh                    <- git stage + status
├── PKGBUILD                 <- build script
├── config                   <- Liquorix config-arch-64
├── v7.0.7-lqx1.patch        <- Liquorix zen patch
└── kernels/
    └── <timestamp>/
        ├── linux-kiro-lqx-*.pkg.tar.zst
        ├── linux-kiro-lqx-headers-*.pkg.tar.zst
        └── build-info.md
```

## Manual Build (Skip the Wrapper)

```bash
makepkg -si --skippgpcheck
```

## Cleanup Build Artifacts

```bash
./clean.sh
```

## Updating to a New Kernel Version

1. Get the new lqx patch from `damentz/liquorix-package` GitHub, branch `7.0/master`, path `debian/patches/zen/`
2. Copy to this directory, rename to `v<ver>-<lqxrel>.patch`
3. Update `_minor`, `_lqxrel`, `pkgrel` in PKGBUILD
4. Run `./build-kernel.sh` — checksums update automatically

## FAQ

**Q: Can I copy this kernel to another machine?**
A: No. Built with `-march=native` for this CPU. Will crash on different hardware.

**Q: Why no gaming/desktop preset like linux-kiro?**
A: The Liquorix profile is already tuned for low-latency desktop. No need for dual configs.

**Q: What is PDS vs BORE?**
A: Both target desktop responsiveness. PDS (Project-C) is part of the Liquorix patchset; BORE is used in linux-kiro/CachyOS. Different algorithmic approach, similar goals.

**Q: Why madvise for THP instead of always?**
A: Avoids surprise latency spikes from aggressive memory compaction. Apps that benefit from huge pages opt in via `madvise()`.

**Q: How much faster is modprobed-db?**
A: 30–50% build time reduction by compiling only modules your hardware actually uses.
