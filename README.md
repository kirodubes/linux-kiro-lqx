# linux-kiro-lqx

A custom Arch Linux kernel for this machine only, based on the [Liquorix](https://liquorix.net/) lqx patchset applied to a vanilla kernel source. Uses the PDS (Project-C) alternative scheduler — the key distinction from `linux-kiro` which uses BORE.

## Features

- **PDS Scheduler**: Project-C scheduling algorithm optimized for low-latency desktop responsiveness
- **Liquorix Patchset**: lqx patch applied directly to vanilla kernel.org source
- **Performance**: -O3 compiler optimization, 1000Hz tick rate, full preemption
- **Native-only**: Always compiled with `-march=native` for this machine (Intel i7-10700K)
- **Localmod**: Always built with `modprobed-db` — only modules your hardware needs

## Building

### Prerequisites

```bash
sudo pacman -S base-devel
yay -S modprobed-db
```

### Recommended: build-kernel.sh

```bash
cd /home/erik/KIRO/linux-kiro-lqx
./build-kernel.sh
```

This will:
1. Install `modprobed-db` if missing
2. Store currently loaded modules into `~/.config/modprobed.db`
3. Optionally open `nconfig` for manual kernel tweaking
4. Run `updpkgsums` to refresh checksums
5. Build the kernel with `makepkg`
6. Archive `.pkg.tar.zst` files into `kernels/<timestamp>/`

Build time: 30–60 min. With modprobed-db active: 30–50% faster (only your hardware's modules compiled).

### Direct Build

```bash
makepkg -si --skippgpcheck
```

### Cleanup

```bash
./clean.sh
```

## Kernel Profile (Fixed)

This kernel has a single fixed profile — no gaming/desktop toggle. All settings are permanent:

| Setting    | Value                      |
|------------|----------------------------|
| Source     | Vanilla 7.0.7 + lqx1 patch |
| Scheduler  | PDS (Project-C)            |
| HZ         | 1000                       |
| Preemption | Full                       |
| Tickless   | Full (NO_HZ_FULL)          |
| CPU opt    | Native (always)            |
| TCP        | BBR                        |
| THP        | madvise                    |
| O3         | Yes                        |
| Localmod   | Always (modprobed-db)      |

## Advanced Build Options

Edit the top of `PKGBUILD` to enable optional sub-packages:

```bash
_build_nvidia_open=no   # yes/no — NVIDIA open module (Turing+ GPUs)
_build_zfs=no           # yes/no — ZFS module
_build_r8125=no         # yes/no — Realtek r8125 network driver
_build_debug=no         # yes/no — debug symbols package
_use_llvm_lto=none      # none, thin, full — LTO mode (default: GCC, no LTO)
```

## Verification

After installing and rebooting:

```bash
uname -r                                    # expect: 7.0.7-kiro-lqx
zcat /proc/config.gz | grep CONFIG_SCHED_PDS
zcat /proc/config.gz | grep CONFIG_HZ=
zcat /proc/config.gz | grep CONFIG_PREEMPT=
cat /sys/kernel/mm/transparent_hugepage/enabled
```

## Updating to a New Kernel Version

1. Download the new lqx patch from `damentz/liquorix-package` on GitHub, branch `7.0/master` (path: `debian/patches/zen/`)
2. Copy it here, rename to `v<ver>-<lqxrel>.patch`
3. Update `_minor`, `_lqxrel`, `pkgrel` in `PKGBUILD`
4. Run `./build-kernel.sh` — `updpkgsums` recalculates automatically

## Hardware Notes

The included `config` is the Liquorix `config-arch-64`, trimmed for this machine (Intel i7-10700K, wired ethernet, no WiFi, no AMD GPU):

- **WiFi disabled** — wired-only machine
- **AMD GPU disabled** — Intel iGPU only
- **Nouveau disabled** — no NVIDIA open

If you build on different hardware, re-enable relevant options via `nconfig` or set `_use_current=yes` in PKGBUILD to base the config on your running kernel.

> **Native CPU warning**: This kernel is compiled with `-march=native` for the exact CPU it was built on. Do not copy the built package to another machine — it will crash or refuse to boot. Rebuild from source on any new hardware.

## Source

- Kernel Source: [kernel.org](https://www.kernel.org/)
- Liquorix Patchset: [damentz/liquorix-package](https://github.com/damentz/liquorix-package)
- PDS Scheduler: part of the lqx patchset (Project-C by Alfred Chen)
- Claude Code Onboarding Guide: https://claude.ai/claude-code/onboard/WWvIE2tARwuU

## License

GPL-2.0-only (same as Linux kernel)

## Credits

- **Liquorix / lqx patchset**: Steven Barrett (damentz)
- **PDS Scheduler**: Alfred Chen (Project-C)
- **linux-kiro-lqx**: Erik Dubois
