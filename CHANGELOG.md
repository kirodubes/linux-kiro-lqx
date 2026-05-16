# Changelog — linux-kiro-lqx

## 2026.05.15

### What Changed
Initial creation of the linux-kiro-lqx package: a Liquorix/PDS kernel for Kiro, built exclusively for this machine.

### Technical Details
- Source: vanilla Linux 7.0.7 from kernel.org + Liquorix lqx1 patch (`v7.0.7-lqx1.patch`)
- Scheduler: PDS (Project-C alternative scheduler, included in the lqx patchset)
- Config base: Liquorix `config-arch-64` (Debian-generated, adapted for Arch packaging)
- Always native CPU (`-march=native`), always `localmodconfig` via modprobed-db
- HZ: 1000, preemption: full, tickless: full, TCP default: BBR
- LTO optional (none/thin/full), optional nvidia-open/ZFS/r8125 sub-packages
- Helper scripts: `build-kernel.sh`, `clean.sh`, `up.sh`

### Files Modified
- PKGBUILD (new)
- config (new — from Liquorix config-arch-64)
- v7.0.7-lqx1.patch (new — from damentz/liquorix-package)
- build-kernel.sh (new)
- clean.sh (new)
- up.sh (new)
- .gitignore (new)
- CLAUDE.md (new)
- CHANGELOG.md (new)
