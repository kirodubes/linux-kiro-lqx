# Changelog — linux-kiro-lqx

## 2026.05.16

### What Changed
Full documentation suite written and published. PKGBUILD compared with the Chaotic-AUR upstream linux-lqx. Shareable onboarding template created for anyone wanting to build their own custom kernel with Claude.

### Technical Details
- Fetched Chaotic-AUR linux-lqx PKGBUILD from GitLab for comparison
- Key differences documented: our PKGBUILD hardcodes native CPU + mandatory modprobed-db + PDS-only, adds LTO support and sub-packages (nvidia-open, ZFS, r8125, debug), uses ZSTD_CLEVEL=19 and module signing; Chaotic's is generic, scheduler-selectable, pulls patches dynamically from the liquorix-package tarball
- CLAUDE.md updated with Reference links section (Chaotic PKGBUILD URL + Liquorix patch source)
- ONBOARDING.md written as a generic template for anyone starting a custom Arch kernel project; shared via Claude Code onboarding link: https://claude.ai/claude-code/onboard/WWvIE2tARwuU
- GitHub push initially failed: `erikdubois` SSH key not added as collaborator on `kirodubes/linux-kiro-lqx`; resolved by adding collaborator access

### Files Modified
- README.md (new)
- SETUP.md (new)
- QUICKSTART.md (new)
- BUILD_SCRIPT_README.md (new)
- COMPARISON.md (new)
- ONBOARDING.md (new)
- CLAUDE.md (updated — added Reference links section)

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
