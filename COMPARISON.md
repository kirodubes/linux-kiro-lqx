# PKGBUILD Comparison: linux-kiro-lqx vs linux-lqx (Chaotic-AUR)

Upstream reference: https://gitlab.com/chaotic-aur/pkgbuilds/-/blob/main/linux-lqx/PKGBUILD  
Maintainer: Piotr Gorski (Chaotic-AUR)

---

## 1. Package Identity

| | linux-kiro-lqx (ours) | linux-lqx (Chaotic) |
|---|---|---|
| pkgbase | `linux-kiro-lqx` | `linux-lqx` |
| Build host | `kiro` | `archlinux` |
| URL | erikdubois/linux-kiro-lqx | liquorix.net |
| Target | This machine only | Generic Arch |

---

## 2. Patch Application

**Chaotic**: Downloads the full `liquorix-package` tarball from GitHub (which bundles kernel, config, and patches). Applies patches by reading the `series` file from `debian/patches/` — multiple discrete patch files applied in order.

**Ours**: Ships a single pre-combined `v7.0.7-lqx1.patch` file alongside the PKGBUILD. Simpler to maintain at the cost of having to manually update the patch file on each release.

**Impact**: Chaotic's approach automatically picks up any new patches added to the liquorix-package tarball without a PKGBUILD change. Our approach gives tighter control over exactly what goes in.

---

## 3. Version Detection

**Chaotic**: Reads `abiname` dynamically from `debian/config/defines` inside the downloaded tarball. Adapts automatically when upstream bumps the minor version or patchrel.

**Ours**: `_minor` and `_lqxrel` are hardcoded in the PKGBUILD. Must be bumped manually on each release.

---

## 4. Config Source

**Chaotic**: Pulls `config-arch-64` directly from the downloaded liquorix-package tarball — always in sync with the patch set.

**Ours**: Ships a local `config` file that was downloaded from Liquorix at setup time. Must be manually refreshed on major kernel bumps.

---

## 5. CPU Scheduler

**Chaotic**: Configurable via `_projectc` variable: `'bmq'`, `'pds'`, or `'none'` (CFS).

**Ours**: PDS hard-coded. `scripts/config -e CONFIG_SCHED_PDS` is unconditional — no way to switch without editing the PKGBUILD.

---

## 6. CPU Optimization

**Chaotic**: No CPU-specific optimization. Builds for generic x86_64.

**Ours**: Always enables `X86_NATIVE_CPU` (`-march=native`). This kernel is non-portable by design — built for the i7-10700K only.

---

## 7. localmodcfg

**Chaotic**: Optional (`_localmodcfg=`). User opts in; skips if no modprobed.db.

**Ours**: Mandatory. The build **dies** if `~/.config/modprobed.db` is missing. This is intentional — this kernel is for this machine only; a full module build would be wasted.

---

## 8. LTO Support

**Chaotic**: No LTO support. GCC only.

**Ours**: Optional `_use_llvm_lto=none/thin/full`. When enabled, pulls in Clang/LLVM and sets `CC=clang LD=ld.lld LLVM=1 LLVM_IAS=1`.

---

## 9. Sub-packages

| Sub-package | linux-kiro-lqx | linux-lqx (Chaotic) |
|---|---|---|
| headers | yes | yes |
| nvidia-open | optional (`_build_nvidia_open`) | no |
| ZFS | optional (`_build_zfs`) | no |
| r8125 | optional (`_build_r8125`) | no |
| debug (vmlinux) | optional (`_build_debug`) | no |
| docs (htmldocs) | no | optional (`_htmldocs_enable`) |

---

## 10. Module Compression

**Chaotic**: Standard `modules_install` with `INSTALL_MOD_STRIP=1`.

**Ours**: Adds `ZSTD_CLEVEL=19` for maximum compression, reducing installed module size.

---

## 11. Module Signing

**Chaotic**: No module signing logic.

**Ours**: Has a `_sign_modules()` helper that strips and signs all `.ko` files using the kernel's built-in signing key. Used by the nvidia-open, ZFS, and r8125 sub-packages.

---

## 12. makedepends

**Ours** includes everything Chaotic has, plus: `binutils`, `glibc`, `libgcc`, `openssl`, `rust-bindgen`, `xxhash`, `zlib`. These are needed by the optional LTO path and sub-packages (ZFS, nvidia-open).

---

## 13. Arch-Specific Tweaks

Both apply the same three Arch-specific config adjustments:

- `CONFIG_DEBUG_INFO_DWARF5`
- TOMOYO paths (`/usr/bin/tomoyo-init`, `/usr/lib/systemd/systemd`)
- `CONFIG_LSM = landlock,lockdown,yama,bpf`

Chaotic also applies these. Ours matches.

---

## Summary

| Area | Chaotic linux-lqx | linux-kiro-lqx |
|------|-------------------|----------------|
| Patch source | tarball series (auto-updates) | single pre-merged patch |
| Version detection | dynamic from tarball | hardcoded |
| Config source | from tarball (always in sync) | local file (manual refresh) |
| Scheduler | selectable (bmq/pds/none) | PDS only |
| CPU optimization | generic | native (non-portable) |
| localmodcfg | optional | mandatory |
| LTO | none | optional (thin/full) |
| Extra packages | docs | nvidia-open, ZFS, r8125, debug |
| Module compression | standard | ZSTD level 19 |
| Module signing | no | yes |
| Portability | any Arch machine | this machine only |

**Ours is more opinionated**: native CPU, mandatory modprobed-db, PDS-only, but adds LTO and sub-package support that Chaotic doesn't have. Chaotic is more general-purpose and follows upstream liquorix-package more closely.
