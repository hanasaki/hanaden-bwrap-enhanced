<!-- (c) 2026-* Frederick Bloom -- README.md -- Hanaden AI -->

# V-Universe by Hanaden

**Rootless, kernel-enforced containment for AI agents, developer workflows, and desktop apps.**

[![Version: 0.4.0-beta](https://img.shields.io/badge/Version-0.4.0--beta-blue.svg)](CHANGELOG.md)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE.md)
[![Dual-License: Commercial](https://img.shields.io/badge/Dual--License-Commercial-orange.svg)](PROJECT_HOME/docs/legal/FrederickBloom/LICENSE-COMMERCIAL.md)
[![TDD: 875 assertions · 53 suites](https://img.shields.io/badge/TDD-875%20assertions%20·%2053%20suites-brightgreen.svg)](PROJECT_HOME/src/test/hanaden-bwrap-enhanced/)
[![Zero Side Effects](https://img.shields.io/badge/Security-Zero%20Side%20Effects-success.svg)](CONSTITUTION.md)

---

## What it does

V-Universe wraps [Bubblewrap](https://github.com/containers/bubblewrap) to construct a
purpose-built Virtual Filesystem (VFS) per sandbox invocation using unprivileged Linux
user namespaces. No root. No daemons. No host mutation.

The security boundary is the **mount namespace itself** — unmounted files are invisible,
not merely access-denied. Governed by **The Immutable Principle**: jail designed externally,
enforced by the kernel, never self-policed by the prisoner. See [`CONSTITUTION.md`](CONSTITUTION.md).

## Documentation

📖 **[hanasaki.github.io/hanaden-bwrap-enhanced/site/](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/)**

| | Business | Technical |
|:---|:---|:---|
| **Product** | [Overview](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/business/project-core/index.html) · [Features](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/business/project-core/features.html) · [Security](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/business/project-core/security.html) · [Licensing](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/business/project-core/pricing.html) | [Architecture](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/technical/project-core/architecture.html) · [CLI Reference](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/technical/project-core/cli-reference.html) · [Security Model](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/technical/project-core/security-model.html) · [Test Harness](https://hanasaki.github.io/hanaden-bwrap-enhanced/site/technical/project-core/test-harness.html) |

---

## CLI

Multi-subcommand dispatcher following the `git` / `systemctl` pattern.

```
bwrap-enhanced.sh  SUBCOMMAND  [OPTIONS]
bwrap-enhanced.sh  --help | -h       # dispatch table, exit 0
bwrap-enhanced.sh  --version | -v    # version string, exit 0
```

### Subcommands

| Subcommand | Status | Purpose |
|:---|:---|:---|
| `provision` | full | Create virtual root skeleton (NOT idempotent) |
| `fsck` | full | Check / repair virtual root integrity |
| `start` | full | Launch an isolated process inside the sandbox |
| `stop` | stub | Stop a running sandbox (not yet implemented) |
| `ls` | stub | List known virtual roots (not yet implemented) |

### `provision` — create virtual root

```
bwrap-enhanced.sh provision [OPTIONS]

  --host-real-root        PATH          (default: ~/virtual-roots; MUST NOT exist)
  --virtual-user-name     NAME          (default: sandbox_user)
  --host-real-home-parent PATH          (default: HOST_REAL_ROOT/home)
  --log-level             NAME|NUMBER   (default: INFO)
  -n, --dry-run                         (show what would be created)
```

> **Not idempotent.** If `--host-real-root` already exists, `provision` fails. Use `fsck` to validate and repair.

### `fsck` — check / repair virtual root

```
bwrap-enhanced.sh fsck [ROOT_PATH] [OPTIONS]

  --host-real-root        PATH          (default: ~/virtual-roots)
  --virtual-user-name     NAME          (default: sandbox_user)
  --log-level             NAME|NUMBER   (default: INFO)
  -n                                    (check only — no repairs)
  -a                                    (auto-repair)
  -r                                    (interactive)
  -f                                    (force)
  -v                                    (verbose)
```

### `start` — launch isolated process

```
bwrap-enhanced.sh start [OPTIONS] -- CMD [ARG...]

  --host-real-root        PATH          (default: ~/virtual-roots; MUST exist)
  --virtual-user-name     NAME          (default: sandbox_user)
  --host-real-home-parent PATH          (default: HOST_REAL_ROOT/home)
  --log-level             NAME|NUMBER   (default: INFO)
  -n, --dry-run                         (resolve + print bwrap argv; no exec)
  --validate                            (validate flags + paths; no exec)

  # Boolean passthroughs  (default: absent = deny)
  --net-passthrough       [true|false]
  --env-passthrough       [true|false]
  --x11-passthrough       [true|false]  (implied by wayland/gnome/kde)
  --wayland-passthrough   [true|false]  (implies x11)
  --audio-passthrough     [true|false]
  --a11y-passthrough      [true|false]
  --dbus-passthrough      [true|false]  (NEVER implied — always explicit)
  --gnome-passthrough     [true|false]  (implies x11)
  --kde-passthrough       [true|false]  (implies x11)

  # Graded passthroughs   (absent < ro < rw)
  --mise-passthrough      [ro|rw]       (default: off; bare flag = ro)
  --local-bin-passthrough [ro|rw]       (default: off; bare flag = ro)
```

**Privilege grading:** `absent` < `ro` < `rw`. Bare flag = most restrictive ON state.
Passing `--flag false` is an error — omit the flag to deny.

---

## Security tiers

| Tier | `start` flags added | Trust | Use case |
|:---|:---|:---|:---|
| **0** | *(none)* | Max | AI agents, untrusted scripts, CI |
| **1** | `--wayland-passthrough --audio-passthrough` | High | Sandboxed desktop apps |
| **2** | + `--a11y-passthrough` | High | Accessibility tooling |
| **3** | + `--dbus-passthrough` | Medium | File-picker portals |
| **4** | + `--gnome-passthrough` / `--kde-passthrough` | Low | Full desktop integration |

---

## Verification

```bash
./PROJECT_HOME/src/test/hanaden-bwrap-enhanced/run_phase1.sh
```

875 assertions · 42 feature suites · 53 test files · JUnit XML · JaCoCo coverage · HTML dashboard.

---

## License

Copyright (c) 2026-* **Frederick Bloom**. All rights reserved.  
AGPL-3.0-only with Section 7 Additional Terms. Commercial licenses available.  
Contact: **devlabs@hanaden.com** · [LICENSE.md](LICENSE.md)
