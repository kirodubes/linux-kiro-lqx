# Custom Arch Linux Kernel — Claude Onboarding Template

> **Load this guide into Claude Code**: https://claude.ai/claude-code/onboard/WWvIE2tARwuU

This is a template CLAUDE.md for anyone building a custom Arch Linux kernel package with Claude Code. Copy the relevant sections into your own project's `CLAUDE.md` and fill in your specifics.

---

## How to use this template

1. Create a directory for your kernel project: `mkdir ~/my-kernel && cd ~/my-kernel`
2. Copy your `PKGBUILD`, `config`, and patch files in
3. Create a `CLAUDE.md` from the template below
4. Open Claude Code in that directory — it reads `CLAUDE.md` automatically

---

## Template: CLAUDE.md

```markdown
# CLAUDE.md

## Project

Custom Arch Linux kernel package (`<pkgname>`) based on <upstream source>.
Built for: <your hardware — e.g. Intel i7-10700K, AMD Ryzen 7 5800X, etc.>

## Kernel profile

| Setting    | Value                          |
|------------|--------------------------------|
| Source     | <e.g. vanilla 6.x + lqx patch / CachyOS tarball> |
| Scheduler  | <BORE / PDS / EEVDF / CFS>     |
| HZ         | <1000 / 500 / 300>             |
| Preemption | <full / lazy / dynamic>        |
| CPU opt    | <native / generic_v3 / generic>|
| TCP        | <BBR / cubic>                  |
| THP        | <madvise / always / never>     |
| O3         | <yes / no>                     |
| Localmod   | <yes (modprobed-db) / no>      |
| LTO        | <none / thin / full>           |

## Build commands

# Replace with whatever your project uses
./build-kernel.sh           # wrapper script (recommended)
makepkg -si --skippgpcheck  # direct build
./clean.sh                  # remove build artifacts

## Architecture

**PKGBUILD** — core build script. Key options at the top:
- List your PKGBUILD variables and what they do

**config** — kernel config base. Source: <where it came from>

**<patch file>** — patchset applied to vanilla kernel. Source: <upstream URL>

**build-kernel.sh** — wrapper script. Describe what it does.

## Upstream references

- Upstream PKGBUILD reference: <URL to the AUR/Chaotic/CachyOS PKGBUILD you based yours on>
- Patch source: <URL>
- Config source: <URL>

## Updating to a new kernel version

1. <Step 1 — e.g. download new patch>
2. <Step 2 — e.g. update _minor/_patchrel in PKGBUILD>
3. <Step 3 — e.g. run build-kernel.sh, updpkgsums runs automatically>

## Post-build verification

uname -r                              # check kernel version
zcat /proc/config.gz | grep CONFIG_SCHED_   # check scheduler
zcat /proc/config.gz | grep CONFIG_HZ=      # check tick rate
zcat /proc/config.gz | grep CONFIG_PREEMPT= # check preemption
cat /sys/kernel/mm/transparent_hugepage/enabled

## Hardware notes

- CPU: <your CPU>
- GPU: <your GPU — note if you disabled wifi/AMD/nouveau in config>
- Network: <wired / wifi>
- Special hardware: <anything that needs a module or config flag>

## Current state

<Short description of where the project is — e.g. "PKGBUILD at 6.12.1, first build done, running stably.">
```

---

## Tips for working with Claude on kernel builds

### Be specific about your hardware

The kernel config is hardware-dependent. Tell Claude exactly what CPU, GPU, and network card you have. Options like `-march=native`, WiFi module inclusion, and GPU driver selection all depend on this.

### Share your PKGBUILD variables

When asking Claude to help tune settings, paste the variable block at the top of your PKGBUILD. Claude needs to see `_cpusched`, `_HZ_ticks`, `_preempt`, `_hugepage`, etc. to give accurate advice.

### Use modprobed-db

Install `modprobed-db` from the AUR and let it run for a few hours before building. It reduces build time by 30–50% by compiling only modules your hardware actually uses. Ask Claude to wire it into your build script.

### Keep a CHANGELOG.md

Ask Claude to update it after each session. It becomes the project memory — version bumps, config changes, and decisions made are all recorded there.

### Useful starting questions for Claude

- "Read my PKGBUILD and explain what each variable at the top does"
- "Compare my PKGBUILD with [upstream URL] and tell me what's different"
- "Write a build-kernel.sh wrapper that handles modprobed-db and archives packages"
- "What should I verify after installing this kernel to confirm it's running correctly?"
- "My build failed with this error: [paste error] — what's wrong?"
- "I'm on kernel X.Y.Z — what do I need to update to bump to X.Y.Z+1?"

### Scheduler quick reference

| Scheduler | Good for | Source |
|-----------|----------|--------|
| BORE | Gaming, low-latency desktop | CachyOS / linux-kiro |
| PDS | Low-latency desktop | Liquorix lqx patchset |
| EEVDF | Balanced desktop/server | Vanilla kernel (default) |
| BMQ | Alternative desktop | Liquorix lqx patchset |
| CFS | Generic / server | Vanilla kernel (legacy) |

### Common PKGBUILD patterns

**localmodconfig with modprobed-db:**
```bash
if [ -f "$HOME/.config/modprobed.db" ]; then
    make LSMOD="$HOME/.config/modprobed.db" localmodconfig
fi
```

**Native CPU:**
```bash
scripts/config -e X86_NATIVE_CPU
```

**Arch-specific tweaks (always include these):**
```bash
scripts/config -e CONFIG_DEBUG_INFO_DWARF5
scripts/config --set-str CONFIG_SECURITY_TOMOYO_POLICY_LOADER "/usr/bin/tomoyo-init"
scripts/config --set-str CONFIG_SECURITY_TOMOYO_ACTIVATION_TRIGGER "/usr/lib/systemd/systemd"
scripts/config --set-str CONFIG_LSM "landlock,lockdown,yama,bpf"
```

---

## Real examples to study

- **linux-kiro-lqx** — Liquorix/PDS kernel, single fixed profile, native CPU: https://github.com/kirodubes/linux-kiro-lqx
- **linux-kiro** — CachyOS/BORE kernel, gaming + desktop presets: https://github.com/kirodubes/linux-kiro
- **linux-lqx (Chaotic-AUR)** — upstream Liquorix reference: https://gitlab.com/chaotic-aur/pkgbuilds/-/blob/main/linux-lqx/PKGBUILD
- **linux-cachyos-bore** — upstream CachyOS BORE reference: https://github.com/CachyOS/linux-cachyos/blob/master/linux-cachyos-bore/PKGBUILD
