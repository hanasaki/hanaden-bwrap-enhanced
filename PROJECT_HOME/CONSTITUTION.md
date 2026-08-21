<!-- (c) 2026-* Frederick Bloom -- PROJECT_HOME/CONSTITUTION.md -- Hanaden AI -->

# Project Constitution — bwrap-enhanced (Local Pointer)

* **Canonical Constitution:** [`CONSTITUTION.md`](file:///homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/CONSTITUTION.md) (Repository Root)
* **Author:** Frederick Bloom <devlabs@hanaden.com>
* **Copyright:** (c) 2026-* **Frederick Bloom**. All rights reserved.
* **SPDX-License-Identifier:** `AGPL-3.0-only` (Dual Licensed with Commercial License)

---

## Single Source of Truth Notice

The supreme, binding governance document for `bwrap-enhanced` is located at the workspace root:
**[`../../CONSTITUTION.md`](../CONSTITUTION.md)**.

All sub-modules, test runners, execution environments, and downstream consumers MUST adhere to the invariants defined in the root Constitution:

1. **The Immutable Principle:**
   * **External Construction:** The jailer designs and provisions the jail before execution.
   * **External Enforcement:** The sandbox and kernel guards enforce the boundaries from the outside.
   * **Zero Self-Policing:** Never trust or enable a prisoner to build their own cell, alter their confines, or enforce rules upon themselves.
2. **Zero Side-Effects Mandate:** Zero host mutations or directory creation during sandbox boot.
3. **Read-Only Root with Controlled Egress:** Root `/` locked read-only; egress strictly via `/home/[USER]`.
4. **Suppression of Host Artifacts:** Complete shadowing of `/etc/profile.d`, `/tmp`, and `/homes`.
5. **Foreground Hold Init Loop:** Non-polling PID 1 child reaping via bash built-ins.
6. **Dual License & Mandatory Attribution:** AGPL-3.0-only + Commercial dual licensing with moral rights, AI training prohibition, and explicit indemnification.

For detailed specification hierarchy and test suite mapping, refer to [`PROJECT_HOME/README.md`](README.md).
