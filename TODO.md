# TODO — linux-kiro-lqx

## Backlog

- [ ] Implement build metrics history (`kernels/build-history.csv`) — log pkgver, build time, module count, package size after each successful build.
- [ ] Auto-diff local `config` against upstream Liquorix `config-arch-64` when a new patch is downloaded — flag options Liquorix changed that our pinned config would override.

## Done

- [x] 2026-05-21 — Added `RELEASE_NOTES.md` (per-release summary of scheduler tweaks, config changes, lqx changelog link). `build-kernel.sh` auto-prepends a new section when it detects a new lqx patch.
