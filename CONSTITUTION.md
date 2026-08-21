<!-- (c) 2026-* Frederick Bloom -- CONSTITUTION.md -- Hanaden AI -->

# Project Constitution — bwrap-enhanced

* **Author:** Frederick Bloom <devlabs@hanaden.com>
* **Effective Date:** 2026-08-21
* **Project Name:** `hanaden-bwrap-enhanced`
* **Project Name Short:** `Hanaden.BwrapEnhanced`
* **Copyright:** (c) 2026-* **Frederick Bloom**. All rights reserved.
* **SPDX-License-Identifier:** `AGPL-3.0-only` (Dual Licensed with Commercial License)

---

## Preamble

Autonomous AI agents, coding assistants, and modern developer tooling execute arbitrary commands, download packages, and mutate filesystems — frequently with the full privileges of the host developer. Uncontained execution directly on a host machine presents an unacceptable security, stability, and reproducibility hazard.

**`bwrap-enhanced`** is engineered to resolve this risk: a single, deterministic, zero-config utility that drops any process — human, CI/CD runner, or AI agent — into an inescapable, namespace-isolated, read-only-root virtual universe (vuniverse) with strict egress controls, identity injection, zero side effects on the host, and selective GUI/desktop passthrough.

### Core Motivators

1. **Containment by Default:** Contain AI agents and developers within a controlled world without host escape. No process shall mutate the host filesystem unless explicitly routed through designated egress write-holes.
2. **Zero-Config Rootless Security:** Security must be the default path. Zero daemons, zero kernel modules, zero `sudo` / root requirements.
3. **The Immutable Principle:** *The jailer builds the jail; never trust a prisoner to build their own jail, or anyone else's jail.* The sandbox environment is completely pre-structured by the trusted host environment before child process instantiation.
4. **Desktop & GUI Capable:** Sandbox workloads must support rich rendering (Wayland, X11, PipeWire/PulseAudio, accessibility) without compromising filesystem boundaries.
5. **Deterministic Auditability:** Every namespace boundary, mount table, and environment sanitization rule is rigorously verified through executable specifications.

---

## Article I — Purpose & Scope

### §1. Primary Purpose
`bwrap-enhanced` serves as the foundational **Vuniverse / Sandbox Creator** within the Hanaden ecosystem. It builds an isolated, immutable sandbox environment and executes a target command within an unprivileged Bubblewrap sandbox while enforcing hardened Linux namespace and mount configurations.

### §2. Reusable Foundation
`bwrap-enhanced` operates as an independent, standalone security utility. Upstream systems (such as AI booters, session microkernels, CI runners, or IDE plugins) consume `bwrap-enhanced` as an immutable infrastructure component without altering its core isolation invariants.

---

## Article II — The Immutable Security Invariants

The following invariants are absolute (RFC 2119: **MUST**, **MUST-NOT**).

### §1. The Immutable Principle (Jailer vs. Prisoner)
- The host-side invocation environment (the jailer) MUST fully provision all required directories, mountpoints, and identity files prior to executing the sandbox.
- The sandboxed process (the prisoner) MUST-NOT create, alter, or negotiate its own container boundaries or anyone else's.
- Never trust a prisoner to build their own jail or anyone else's jail.

### §2. Zero Side-Effects Mandate
- `bwrap-enhanced.sh` MUST-NOT create host directories, write scratch files, or mutate host configuration outside the explicitly bound paths.
- If a required host root (`--host-real-root`) or host home (`--host-real-home-parent`) does not exist on the host, `bwrap-enhanced.sh` MUST immediately terminate with an informative diagnostic FATAL error.

### §3. Read-Only Root with Controlled Egress
- The container root filesystem (`/`) MUST be locked read-only (`--remount-ro /`).
- The virtual user home (`/home/[VIRTUAL_USER_NAME]`) MUST be the sole persistent read-write egress channel when bound to a host directory.
- Temporary filesystems (`/tmp`, `/dev/shm`, `/run/user/[UID]`) MUST be backed by clean, volatile `tmpfs` instances that evaporate upon container termination.

### §4. Host Contamination Suppression
- Host login and shell initialization scripts (`/etc/profile`, `/etc/profile.d`, `/etc/bash.bashrc`) MUST be shadowed or suppressed with sanitized minimal equivalents to prevent host `PATH` or environment leaks.
- In `--clear-env` mode, all host environment variables MUST be wiped except explicitly authorized runtime variables.

### §5. Zero-Poll PID 1 Foreground Hold
- The wrapper script executes as PID 1 (`--as-pid-1`) inside the sandbox namespace.
- Process tracking and child reaping MUST use native Linux `/proc/1/task/1/children` introspection and bash built-ins (zero external forks) to prevent false-positive process loops.

---

## Article III — Security & Threat Model

| Boundary | Default Posture | Risk & Mitigation |
| :--- | :--- | :--- |
| **Filesystem (VFS)** | Read-Only Root (`/`), Volatile `/tmp` | Egress confined strictly to `/home/[USER]`. Host `/homes` and root hidden. |
| **Network** | **Default-Deny** (`--unshare-net`) | Network namespace isolated unless explicitly opted in via `--share-net`. |
| **User Identity** | Synthetic Injection | Synthetic `/etc/passwd` and `/etc/group` injected via file descriptors. |
| **Wayland Display** | Opt-in (`--enable-wayland`) | Sockets mounted read-only (`wayland-0`). Confined to Wayland protocol security. |
| **X11 Display** | Opt-in (`--enable-x11`) | Sockets mounted RO; `XAUTHORITY` bound read-only. Note: X11 lacks sub-window isolation. |
| **D-Bus Session Bus** | Opt-in (`--enable-dbus`) | **High Risk:** D-Bus portals can expose host file pickers. Enabled only when required. |
| **Desktop Integrations** | Opt-in (`--enable-gnome` / `--enable-kde`) | Desktop services (GVFS, Keyring) passed through selectively per security tier. |

---

## Article IV — Quality, Verification & Anti-Regression

1. **Test-Driven Architecture (TDD):** Every feature in `bwrap-enhanced` is governed by a corresponding specification under `PROJECT_HOME/docs/architecture-design-features-specs/` and verified by executable tests in `PROJECT_HOME/src/test/hanaden-bwrap-enhanced/`.
2. **The Sabotage & Mutation Tests:** Tests must verify system behavior under active fault injection and structural isolation failure. Superficial keyword-matching tests are prohibited.
3. **Automated Verification:** All changes to `bwrap-enhanced.sh` must execute clean through `run_phase1.sh` with 100% pass rates across all 45 specs and 77 assertions.

---

## Article V — Legal, Governance & Intellectual Property

1. **Author & Ownership:** `bwrap-enhanced` is the sole intellectual property of **Frederick Bloom**.
2. **Dual-License Framework:**
   * **Open Source:** Licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0-only)** with Section 7 Additional Terms (Perpetual Attribution, Moral Rights Assertion, Prohibition on AI/ML Model Training, and Mandatory CLA).
   * **Commercial License:** Proprietary, closed-source, cloud SaaS, or enterprise deployments require an executed Commercial License Agreement with Frederick Bloom (`devlabs@hanaden.com`).
3. **Indemnification:** All users, distributors, and deployers agree to indemnify, defend, and hold harmless Frederick Bloom from any and all claims, liabilities, damages, and expenses arising from the use or distribution of this software.
