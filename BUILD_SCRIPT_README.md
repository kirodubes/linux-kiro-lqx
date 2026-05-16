# build-kernel.sh — linux-kiro-lqx

The `build-kernel.sh` wrapper handles the full build workflow: modprobed-db refresh, optional nconfig, checksum update, build, and package archiving.

## Quick Start

```bash
./build-kernel.sh
```

## What It Does (in order)

1. **Installs modprobed-db** if not present (via `paru` or `yay`)
2. **Refreshes module database** — runs `modprobed-db store` to capture currently loaded modules
3. **Injects VirtualBox modules** — adds `vboxdrv`, `vboxnetadp`, `vboxnetflt` if missing from the db
4. **Optional nconfig** — prompts to open the kernel config editor before building
5. **Updates checksums** — runs `updpkgsums` to avoid stale checksum failures
6. **Builds the kernel** — `makepkg -s --skippgpcheck`
7. **Archives packages** — moves `.pkg.tar.zst` files to `kernels/<timestamp>/` with a `build-info.md` summary

## modprobed-db

The script always uses modprobed-db — it is not optional. This significantly reduces build time by limiting compilation to modules your hardware actually uses.

### Setup (first time)

```bash
yay -S modprobed-db
# Let the daemon run in the background for a few hours to track your modules
# Then build — the script handles the rest
```

### What You'll See

```
Storing currently loaded modules into modprobed.db...
+ Added missing VirtualBox module: vboxdrv
modprobed.db ready: 148 entries
```

## Optional nconfig

When prompted:

```
Open nconfig to tweak kernel options before building? [y/N]
```

Answering `y` sets `_makenconfig=yes` in PKGBUILD temporarily. It is reset to `no` automatically when the script exits (via a `trap`).

## Automatic Checksum Updates

`updpkgsums` runs before every build, so you never need to update `b2sums` manually after fetching a new kernel tarball or patch.

## Package Archiving

After a successful build, packages are moved to a timestamped directory:

```
kernels/
└── 20260515-214910/
    ├── linux-kiro-lqx-7.0.7-1-x86_64.pkg.tar.zst
    ├── linux-kiro-lqx-headers-7.0.7-1-x86_64.pkg.tar.zst
    └── build-info.md
```

`build-info.md` records the exact build parameters: date, pkgver, pkgrel, lqxrel, CPU, scheduler, HZ, and preemption.

## No Profile Selection

Unlike `linux-kiro`, there is no gaming/desktop menu. `linux-kiro-lqx` has a single fixed profile. The PKGBUILD settings are not modified by this script — edit PKGBUILD directly if you need to change something.

## Troubleshooting

**No AUR helper found**
```bash
# Install paru or yay, then re-run
yay -S modprobed-db
```

**Build fails — missing dependencies**
```bash
makepkg --syncdeps -si --skippgpcheck
```

**Checksum mismatch**
The script runs `updpkgsums` automatically. If it still fails, the source URL may have changed — check PKGBUILD source array.

**Packages not found after build**
The script looks for `*.pkg.tar.zst` in the script directory. If the build succeeded but no packages appear, check `makepkg` output for errors.

## Manual Build (Without Wrapper)

```bash
makepkg -si --skippgpcheck
```

Note: without the wrapper, modprobed-db store is not refreshed and checksums are not updated automatically.
