<!-- (c) 2026-* Frederick Bloom -- CONSTITUTION.md -- Hanaden AI -->

# Project Constitution — bwrap-enhanced

(c) 2026-* Frederick Bloom — All Rights Reserved — Hanaden AI

## Preamble

AI agents execute code, install packages, and modify filesystems — often with
the full authority of the user who launched them. An uncontained agent operating
directly on a developer's host is an unacceptable security and stability risk.

**bwrap-enhanced** exists to solve this: a single, deterministic shell command
that drops any process — human or AI — into a namespace-isolated, read-only-root
sandbox with controlled egress, identity injection, and selective GUI passthrough.

### Motivators

1. **Containment by default.** No process should touch the host filesystem
   unless explicitly granted access.
2. **Zero-config security.** The safe path must be the easy path. One command,
   no container images, no daemons, no root.
3. **GUI-capable isolation.** Sandboxed apps must render on the user's desktop
   (Wayland, X11, audio, accessibility) without weakening isolation.
4. **AI-agent-safe execution.** Agents get a full POSIX environment with
   toolchains (mise, compilers, runtimes) but cannot escape the sandbox.
5. **Auditability.** Every isolation boundary is spec'd, tested, and versioned.

### High-Level Features

- Namespace-isolated VFS with read-only root and RW egress home
- Network deny-by-default with opt-in `--share-net`
- Environment sanitization (`--clear-env`) with selective injection
- Virtual user identity (passwd/group cloning, FD injection)
- GUI passthrough: Wayland, X11 (XAUTHORITY RO-bind), PipeWire/PulseAudio
- Desktop integration: GNOME, KDE, D-Bus, GTK themes, fontconfig, Chrome
- Toolchain passthrough: mise shims, arbitrary bind/setenv/unsetenv
- 45 TDD specs, 77 assertions, 10 feature suites

## Article 1: Ownership

All code, specifications, tests, documentation, templates, and configurations
in this repository are the exclusive intellectual property of **Frederick Bloom**.

## Article 2: Licensing

This project is **proprietary software** licensed under All Rights Reserved terms.
No part may be reproduced, distributed, or modified without the prior written
permission of the author. For licensing inquiries: frederick.bloom@hanaden.ai

## Article 3: AI Agent Governance

All AI agents, LLMs, automation, and AI-processors operating within this project
MUST comply with the governance rules defined in `AGENTS.md`, `GEMINI.md`,
`CLAUDE.md`, and `.agents/AGENTS.md`. These rules are **MANDATORY — PRIORITY 0**.

Key principles:
- **Sphere of Control and Influence (SCI):** Each project is isolated.
  Cross-workspace operations require explicit user permission.
- **Single Source of Truth (SST):** Specs → Tests → Code → Runtime must be
  consistent at all times.
- **Anti-Reward-Hacking Mandate:** No shortcuts, no fabrication, no completion
  theater. Real work only.
- **Read Before Writing:** Agents must read specs before generating output.

## Article 4: Code Quality

All changes MUST follow the SDLC TDD discipline:
1. RED test first (proves the defect or gap)
2. GREEN fix (minimal change to pass)
3. Full regression suite (zero regressions)
4. Two consecutive 100% passes = convergence

## Article 5: Branch Governance

GitOps three-tier model:
- `feature/*` → `develop` → `master`
- All merges use `--no-ff` for auditable merge-commit history
- `master` is the release branch; only `develop` merges into it
- Releases are tagged with SemVer (`v0.1.0`)

## Article 6: Security

Security is not optional. All sandbox isolation mechanisms (VFS, network, env,
identity, GUI passthrough) are security boundaries. Changes to these mechanisms
require documented analysis, full test coverage, and spec updates.

Security vulnerabilities are tracked in `docs/security-bulletins/`.
Responsible disclosure: frederick.bloom@hanaden.ai
