# Liquorix Config Drift — linux-kiro-lqx

Per-build comparison of local [`config`](./config) vs upstream `linux-liquorix/debian/config/kernelarch-x86/config-arch-64` on the matching `<major>/master` branch. Newest section first. Auto-prepended by [`build-kernel.sh`](./build-kernel.sh).

Three buckets:

- **A. Overrides** — options where upstream changed value but our pinned config keeps a different one. **These matter most**: a Liquorix upstream change is silently being undone by our config.
- **B. Added by Liquorix** — options upstream now sets that we don't have at all (likely new since our last sync).
- **C. Only in our config** — options we set that upstream doesn't (intentional Kiro customizations, or stale entries to prune).

## 2026-05-22 — 7.0.9-lqx1

- Upstream: <https://raw.githubusercontent.com/damentz/liquorix-package/7.0/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64>
- Counts: **4 overrides** · 1 new upstream · 0 only-local

### A. Options we override (upstream changed value, our config keeps different)

| Option                         | Upstream | Local |
|--------------------------------|----------|-------|
| CONFIG_ANDROID_BINDER_IPC_RUST | y        | n     |
| CONFIG_KVM_AMD                 | m        | n     |
| CONFIG_KVM_AMD_SEV             | y        | n     |
| CONFIG_SECURITY_LANDLOCK       | y        | n     |

### B. Added by Liquorix (not in our config)

- `CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"`
## 2026-05-22 — 7.0.9-lqx1

- Upstream: <https://raw.githubusercontent.com/damentz/liquorix-package/7.0/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64>
- Counts: **4 overrides** · 1 new upstream · 0 only-local

### A. Options we override (upstream changed value, our config keeps different)

| Option                         | Upstream | Local |
|--------------------------------|----------|-------|
| CONFIG_ANDROID_BINDER_IPC_RUST | y        | n     |
| CONFIG_KVM_AMD                 | m        | n     |
| CONFIG_KVM_AMD_SEV             | y        | n     |
| CONFIG_SECURITY_LANDLOCK       | y        | n     |

### B. Added by Liquorix (not in our config)

- `CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"`
