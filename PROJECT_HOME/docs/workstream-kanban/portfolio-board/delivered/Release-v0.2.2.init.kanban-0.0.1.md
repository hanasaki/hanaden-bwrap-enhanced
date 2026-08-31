---
card-id: RELEASE-v0.2.2
card-type: initiative
title: "Release v0.2.2"
status: delivered
priority: P0
---

# Release v0.2.2

- [x] D-Bus Decoupling — `--enable-gnome`/`--enable-kde` no longer implicitly set `ENABLE_DBUS=true`
- [x] Security Tier Table Rewrite — Tiers reordered to reflect corrected isolation model
- [x] Test Path Portability — `test_gnome_passthrough.sh`/`test_kde_passthrough.sh` use `SCRIPT_DIR` traversal
- [x] GN-005 / KDE-005 — D-Bus decoupling assertions added to both passthrough test scripts
- [x] PortabilityEnforcement DRIV/MOTI hierarchy — 3 portability specs created and linked
