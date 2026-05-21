# TODO — linux-kiro-lqx

## Backlog

- [ ] Auto-diff local `config` against upstream Liquorix `config-arch-64` when a new patch is downloaded — flag options Liquorix changed that our pinned config would override.

## Done

- [x] 2026-05-21 — Build metrics history: `build-kernel.sh` now times `makepkg`, counts `=m` modules in the snapshot config, sums archived package sizes, writes them to per-build `build-info.md` and appends a row to `kernels/build-history.csv` (header auto-created).
- [x] 2026-05-21 — Added `RELEASE_NOTES.md` (per-release summary of scheduler tweaks, config changes, lqx changelog link). `build-kernel.sh` auto-prepends a new section when it detects a new lqx patch.
