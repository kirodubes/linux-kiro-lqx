# Release Notes — linux-kiro-lqx

One section per kernel version bump. Newest at the top. New sections are auto-prepended by `build-kernel.sh` when it detects a new lqx patch on GitHub.

For per-build technical details (timing, modules, package size), see `kernels/<timestamp>/build-info.md`. For day-by-day development changes, see [CHANGELOG.md](CHANGELOG.md).

## 7.0.9-lqx1 (2026-05-19)

Bumped from 7.0.7-lqx1 → 7.0.9-lqx1.

- **Patch source**: https://github.com/damentz/liquorix-package/blob/7.0/master/linux-liquorix/debian/patches/zen/v7.0.9-lqx1.patch
- **Scheduler**: PDS (unchanged)
- **Config changes**: Disabled `CONFIG_KVM_AMD` (Intel-only machine), `CONFIG_ANDROID_BINDER_IPC_RUST` (no Android containers), `CONFIG_SECURITY_LANDLOCK` (compiled-in but never active)
- **lqx changelog**: https://github.com/damentz/liquorix-package/commits/7.0/master

## 7.0.7-lqx1 (initial)

First tracked release of `linux-kiro-lqx`. Forked from `linux-kiro` with the following profile changes:

- **Source**: Vanilla kernel + lqx patch (was: CachyOS pre-patched tarball)
- **Scheduler**: PDS / Project-C (was: BORE)
- **Config base**: Liquorix `config-arch-64` (was: CachyOS config)
- **THP**: `madvise` (was: `always`)
- **Presets**: removed — single fixed profile
