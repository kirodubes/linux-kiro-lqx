# TODO — linux-kiro-lqx

## Backlog

- [ ] Add `RELEASE_NOTES.md` — per-release summary of what changed between kernel versions (scheduler tweaks, config changes, patch notes from lqx changelog). One section per version bump, auto-updated when build-kernel.sh detects a new patch.
- [ ] Implement build metrics history (`kernels/build-history.csv`) — log pkgver, build time, module count, package size after each successful build.
- [ ] Auto-diff local `config` against upstream Liquorix `config-arch-64` when a new patch is downloaded — flag options Liquorix changed that our pinned config would override.

## Done

