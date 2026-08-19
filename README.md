<!-- (c) 2026-* Frederick Bloom -- README.md -- Hanaden AI -->

# bwrap-enhanced

**A security-hardened, namespace-isolated sandbox wrapper for Linux desktop applications and AI agents.**

(c) 2026-* Frederick Bloom — All Rights Reserved — Hanaden AI

## Overview

`bwrap-enhanced.sh` is a comprehensive wrapper around [bubblewrap](https://github.com/containers/bubblewrap) (`bwrap`) that provides:

- **VFS Isolation** — Read-only root, RW egress home, tmpfs overlays, usr-merge symlinks
- **Network Isolation** — Default deny, opt-in `--share-net`
- **Environment Sanitization** — `--clear-env` strips host env, injects only declared vars
- **Identity Injection** — Virtual user, passwd/group cloning, FD-based injection
- **GUI Passthrough** — Wayland, X11 (with XAUTHORITY RO-bind), audio (PipeWire/PulseAudio), accessibility
- **Desktop Integration** — GNOME, KDE, D-Bus, GTK themes, fontconfig, Chrome policies
- **Toolchain Passthrough** — Mise runtime manager, arbitrary bind/setenv/unsetenv

## Quick Start

```bash
# Basic sandbox (no network, no GUI)
./bwrap-enhanced.sh --clear-env --host-real-root / -- /bin/bash

# Full desktop sandbox (X11 + audio + network)
./bwrap-enhanced.sh \
  --clear-env \
  --host-real-root / \
  --share-net \
  --enable-wayland --enable-x11 \
  --enable-audio --enable-a11y \
  --enable-dbus \
  -- /bin/bash

# Run a specific app
./bwrap-enhanced.sh \
  --clear-env --host-real-root / --share-net \
  --enable-wayland --enable-x11 --enable-audio \
  --enable-dbus --enable-gnome \
  -- /usr/bin/firefox
```

## Project Structure

```
hanaden-bwrap-enhanced/
├── PROJECT_HOME/                    # Virtual filesystem jail root
│   ├── boot/
│   │   ├── bwrap-enhanced.sh        # Runtime copy (synced from src/main)
│   │   └── specs/                   # Boot specs (config, cmdstream, design)
│   ├── docs/
│   │   └── architecture-design-features-specs/
│   │       └── BwrapEnhanced2026.strat/  # Full spec hierarchy
│   ├── generic-sldc-and-engine-readonly/ # SDLC engine spec
│   └── src/
│       ├── main/hanaden-bwrap-enhanced/
│       │   └── bwrap-enhanced.sh    # Source of truth
│       └── test/hanaden-bwrap-enhanced/
│           └── BwrapEnhanced2026.strat/  # 45 spec tests
├── docs/
│   └── doc-templates/               # Enterprise templates
├── AGENTS.md / GEMINI.md / CLAUDE.md # AI agent governance
├── LICENSE                          # Proprietary — All Rights Reserved
└── CHANGELOG.md                     # Release history
```

## Test Suite

45 specs across 10 feature suites, 77 assertions:

```bash
# Run full suite
bash PROJECT_HOME/src/test/hanaden-bwrap-enhanced/run_phase1.sh
```

| Suite | Specs | Description |
|-------|-------|-------------|
| ZeroSideEffects | 6 | CLI defaults, fatal error handling, zero mutation |
| VfsIsolation | 5 | Bind sequence, RO root, RW egress, tmpfs, usr-merge |
| NetworkIsolation | 2 | Default deny, --share-net opt-in |
| EnvSanitization | 3 | Env strip, inherit override, XDG vars |
| IdentityInjection | 5 | FD injection, passwd/group cloning, virtual user |
| HostShadowing | 3 | AutoFS shadow, profile suppression/replacement |
| GuiPassthrough | 11 | Wayland, X11, audio, a11y, GNOME, KDE, D-Bus, GTK, fonts, Chrome |
| MisePassthrough | 1 | Mise runtime manager shim passthrough |
| PassthroughArgs | 5 | Bind, setenv, unsetenv, tilde expansion, last-wins |
| ForegroundHold | 4 | Exit code, orphan reap, builtin loop, sync exec |

## License

Proprietary — All Rights Reserved.
(c) 2026-* Frederick Bloom — Hanaden AI

For licensing inquiries: frederick.bloom@hanaden.ai
