<!-- (c) 2026-* Frederick Bloom -- README.md -- Hanaden AI -->

# Hanaden `bwrap-enhanced`

**Rootless, Namespace-Isolated Virtual Filesystem (VFS) Sandbox & Desktop Containerizer**

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)
[![Dual-License: Commercial](https://img.shields.io/badge/Dual--License-Commercial-orange.svg)](PROJECT_HOME/docs/legal/FrederickBloom/LICENSE-COMMERCIAL.md)
[![TDD Specs: 45/45 Passed](https://img.shields.io/badge/TDD%20Specs-45%2F45%20Passed-brightgreen.svg)](PROJECT_HOME/src/test/hanaden-bwrap-enhanced/)
[![Zero Side Effects](https://img.shields.io/badge/Security-Zero%20Side%20Effects-success.svg)](CONSTITUTION.md)

---

## Why `bwrap-enhanced`?

Autonomous AI coding agents, background language servers, and developer scripts execute arbitrary commands, download packages, and write files directly on host machines. Running untrusted or automated workloads directly with full user privileges creates severe risks of host file contamination, credential theft, and accidental system mutation.

`bwrap-enhanced` creates an **inescapable virtual universe (vuniverse)** governed by **The Immutable Principle**:
1. **External Construction:** The jailer designs and provisions the jail before execution.
2. **External Enforcement:** The sandbox and kernel guards enforce the boundaries from the outside.
3. **Zero Self-Policing:** Never trust or enable a prisoner to build their own cell, alter their confines, or enforce rules upon themselves.

### Key Pillars
* **Zero Root / Zero Daemons:** Leverages unprivileged Linux user namespaces via Bubblewrap.
* **Zero Side Effects:** Never creates host directories or mutates host files during startup; fails fast on misconfiguration.
* **Controlled Egress:** Locks root (`/`) read-only and confines filesystem persistence strictly to a dedicated user home write-hole.
* **Native Desktop Passthrough:** Seamlessly runs GUI applications (Wayland, X11, PipeWire/PulseAudio) with fine-grained security tiers.

---

## Architecture & VFS Topology

`bwrap-enhanced` pivots the root filesystem, provisions volatile `tmpfs` layers for scratch storage, and exposes an isolated read-write egress channel.

```mermaid
flowchart LR
    subgraph Host["Host Filesystem (Trusted Jailer Zone)"]
        H_Root["/ (Host Root)"]
        H_Bin["/usr, /bin, /lib"]
        H_Etc["/etc (Configs & Credentials)"]
        H_Tmp["/tmp (Host Temp)"]
        H_Homes["/homes (NFS / User Homes)"]
        H_Egress["EPHEMERAL_HOME/sandbox-user/"]
    end

    subgraph VFS["Vuniverse (Sandbox VFS Boundary)"]
        V_Root["/ (Immutable Read-Only Root)"]
        V_Bin["/usr, /bin, /lib (RO Bind)"]
        V_Etc["/etc (Sanitized: profile.d Shadowed)"]
        V_Id["/etc/passwd, /etc/group (Injected FDs)"]
        V_Tmp["/tmp (Fresh Volatile tmpfs)"]
        V_Homes["/homes (Hidden Empty tmpfs)"]
        V_Home["/home/sandbox-user/ (Live RW Egress Channel)"]
    end

    H_Root -->|--remount-ro /| V_Root
    H_Bin -->|--ro-bind| V_Bin
    H_Etc -->|Shadow profile.d| V_Etc
    Host -.->|FD 9 & 10| V_Id
    H_Tmp -.->|Mask with tmpfs| V_Tmp
    H_Homes -.->|Mask with tmpfs| V_Homes
    H_Egress ==>|--bind RW Write-Hole| V_Home

    style Host fill:#1b2838,stroke:#2a475e,color:#ffffff
    style VFS fill:#171a21,stroke:#66c0f4,color:#ffffff
    style V_Home fill:#1e3d2f,stroke:#4caf50,color:#ffffff
    style V_Root fill:#3b1e1e,stroke:#f44336,color:#ffffff
```

### Sandbox Initialization Flow (MSC)

```mermaid
sequenceDiagram
    participant Host as Host Environment (Jailer)
    participant Bwrap as bwrap-enhanced.sh
    participant VFS as Virtual VFS (Sandbox)
    participant Proc as Workload Process (Prisoner)

    Host->>Bwrap: Invoke with flags & target command
    Bwrap->>Bwrap: Validate host paths exist (Zero-Side-Effects check)
    Bwrap->>Bwrap: Build synthetic /etc/passwd, /etc/group, /etc/profile FDs
    Bwrap->>VFS: Unshare namespaces (user, pid, ipc, uts, cgroup, net)
    Bwrap->>VFS: Bind / read-only, mount tmpfs on /tmp & /homes
    Bwrap->>VFS: Bind host egress dir to /home/[USER] (RW)
    Bwrap->>VFS: Selectively bind Wayland / X11 / Audio sockets (if opted in)
    Bwrap->>Proc: Exec target command as PID 1 foreground hold loop
    Proc->>VFS: Read toolchains & write to /home/[USER]
    Proc->>Host: Process terminates -> volatile tmpfs evaporates immediately
```

---

## Key Features

* **Namespace Isolation:** Enforces isolated user, PID, IPC, UTS, and cgroup namespaces (and default-deny network namespace).
* **Identity Injection:** Injects virtual user identities (`/etc/passwd`, `/etc/group`) via in-memory file descriptors without writing to disk.
* **Shell Environment Sanitization:** Suppresses host `/etc/profile.d` scripts and sanitizes environment variables via `--clear-env`.
* **Toolchain Passthrough:** Integrated `--mise-enable` support for seamless Mise/Cargo/Python development toolchains.
* **Foreground-Hold Engine:** Uses a non-polling bash built-in `/proc` watcher to keep GUI child processes and background daemons alive until complete.
* **Deterministic TDD:** Validated by 45 executable specification tests across 10 feature areas.

---

## Quickstart & CLI Reference

### Basic Usage

```bash
# 1. Run a minimal isolated command (network denied, root RO, volatile /tmp)
./PROJECT_HOME/boot/bwrap-enhanced.sh \
  --clear-env \
  --host-real-root / \
  --host-real-home-parent /tmp/my-sandbox/home \
  -- /bin/bash -c 'echo "Inside sandbox: HOME=$HOME, USER=$USER"'

# 2. Interactive development shell with Mise toolchain
./PROJECT_HOME/boot/bwrap-enhanced.sh \
  --clear-env \
  --host-real-root / \
  --mise-enable \
  -- /bin/bash

# 3. GUI Application (Firefox in Tier 1 Wayland + Audio sandbox)
./PROJECT_HOME/boot/bwrap-enhanced.sh \
  --clear-env \
  --host-real-root / \
  --share-net \
  --enable-wayland --enable-audio \
  -- /usr/bin/firefox
```

### Command-Line Options Matrix

| Flag | Argument | Description | Default |
| :--- | :--- | :--- | :--- |
| `--clear-env` | None | Discard all host environment variables except runtime essentials | Off (Inherit) |
| `--share-net` | None | Opt-in to share host network namespace | Isolated (Deny) |
| `--virtual-user-name` | `NAME` | Name of virtual user inside sandbox (`HOME=/home/NAME`) | `sandbox-user` |
| `--host-real-root` | `PATH` | Host path bound to container root `/` (must exist) | `~/virtual-roots` |
| `--host-real-home-parent`| `PATH` | Host directory containing the user home (must exist) | `~/virtual-roots/home` |
| `--enable-wayland` | None | Bind Wayland display socket read-only | Disabled |
| `--enable-x11` | None | Bind X11 socket and inject `XAUTHORITY` | Disabled |
| `--enable-audio` | None | Bind PipeWire and PulseAudio sockets | Disabled |
| `--enable-a11y` | None | Bind AT-SPI accessibility bus | Disabled |
| `--enable-dbus` | None | Bind D-Bus session bus (*Note: portal escape vector*) | Disabled |
| `--enable-gnome` | None | Enable GNOME desktop services (GVFS, dconf, Keyring) | Disabled |
| `--enable-kde` | None | Enable KDE desktop services (KWallet, KSMServer) | Disabled |
| `--mise-enable` | `[rw]` | Mount host Mise data & shims (RO by default, `rw` optional) | Disabled |
| `--` | `CMD...` | Command and arguments to execute inside the sandbox | Required |

---

## Security & Threat Model

### Security Tiers

| Tier | Configuration | Trust Level | Use Case |
| :--- | :--- | :--- | :--- |
| **Tier 0 (Strict CLI)** | `--clear-env` (default network deny) | **Maximum** | Autonomous AI agents, untrusted scripts, CI runners |
| **Tier 1 (Safe GUI)** | `--enable-wayland --enable-audio` | **High** | Isolated desktop apps (browsers, editors) with no host FS access |
| **Tier 2 (Accessible)**| Tier 1 + `--enable-a11y` | **High** | Screen readers and accessibility tooling |
| **Tier 3 (D-Bus Portal)**| Tier 2 + `--enable-dbus` | **Moderate (Caution)** | File-picker portals can display and access host filesystem |
| **Tier 4 (Full Desktop)**| Tier 3 + `--enable-gnome` / `--enable-kde`| **Low** | Full integration; keyring and virtual filesystem accessible |

---

## Project Structure

```
hanaden-bwrap-enhanced/
├── LICENSE                                    # Custom Dual License (AGPL-3.0 + Commercial)
├── NOTICE                                     # Canonical attribution and moral rights notice
├── CONSTITUTION.md                            # Project invariants and security governance
├── README.md                                  # Enterprise overview & quickstart (this file)
└── PROJECT_HOME/                              # Virtual filesystem jail root
    ├── boot/
    │   ├── bwrap-enhanced.sh                  # Sandbox engine wrapper
    │   └── specs/                             # Specification tree
    ├── docs/
    │   ├── legal/                             # Commercial license, CLA, and third-party terms
    │   │   ├── FrederickBloom/                # CLA.md & LICENSE-COMMERCIAL.md
    │   │   └── third-party/                   # AGPL-3.0.txt
    │   └── architecture-design-features-specs/# SDLC strategy, feature, and spec hierarchy
    └── src/
        ├── main/hanaden-bwrap-enhanced/       # Source of truth implementation
        └── test/hanaden-bwrap-enhanced/       # 45 TDD executable specification tests
            ├── shared/                        # Assertion library & environment setup
            └── run_phase1.sh                  # Test execution runner
```

---

## Verification & Testing

The test suite mirrors the SDLC architecture hierarchy:

```bash
# Execute full Phase 1 specification suite
./PROJECT_HOME/src/test/hanaden-bwrap-enhanced/run_phase1.sh
```

---

## Copyright & License

Copyright (c) 2026-* **Frederick Bloom**. All rights reserved.

Licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0-only)** with Section 7 Additional Terms (Perpetual Attribution, Moral Rights, Prohibition on AI Training, and Mandatory CLA).

Commercial, proprietary, and SaaS deployment licenses are available.  
For licensing inquiries and commercial terms: **devlabs@hanaden.com** | [Commercial Licensing Guide](PROJECT_HOME/docs/legal/FrederickBloom/LICENSE-COMMERCIAL.md)
