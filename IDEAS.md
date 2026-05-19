# Ideas — linux-kiro-lqx

## Claude's Ideashop

**2026.05.19 — Auto-diff config against upstream Liquorix on each version bump**
After downloading a new lqx patch, run a `diff` between the local `config` and the raw `config-arch-64` from `damentz/liquorix-package` to surface options that Liquorix changed upstream but that our pinned `config` would silently override. A one-line `curl | diff - config` during `build-kernel.sh` could flag these before the build starts — catching cases where Liquorix intentionally enables a new feature that our old config would suppress.
