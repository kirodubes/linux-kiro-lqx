# TODO — linux-kiro-lqx

## Backlog

(empty)

## Done

- [x] 2026-05-22 — Auto-diff against upstream `config-arch-64`: `build-kernel.sh` now fetches `linux-liquorix/debian/config/kernelarch-x86/config-arch-64` from the matching `<major>/master` branch on every build, classifies diffs into three buckets (overrides / new upstream / only-local) and prepends a dated section to `CONFIG_DRIFT.md`. Baseline run flagged the four intentional Erik divergences (KVM_AMD, KVM_AMD_SEV, ANDROID_BINDER_IPC_RUST, SECURITY_LANDLOCK) plus one related new upstream entry.
- [x] 2026-05-21 — Build metrics history: `build-kernel.sh` now times `makepkg`, counts `=m` modules in the snapshot config, sums archived package sizes, writes them to per-build `build-info.md` and appends a row to `kernels/build-history.csv` (header auto-created).
- [x] 2026-05-21 — Added `RELEASE_NOTES.md` (per-release summary of scheduler tweaks, config changes, lqx changelog link). `build-kernel.sh` auto-prepends a new section when it detects a new lqx patch.
