<!-- (c) 2026-* Frederick Bloom -- CONSTITUTION.md -- Hanaden AI -->

# Project Constitution — bwrap-enhanced

(c) 2026-* Frederick Bloom — All Rights Reserved — Hanaden AI

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
- **Sphere of Control and Influence (SCI):** Each project is isolated. Cross-workspace operations require explicit user permission.
- **Single Source of Truth (SST):** Specs → Tests → Code → Runtime must be consistent.
- **Anti-Reward-Hacking Mandate:** No shortcuts, no fabrication, no completion theater.
- **Read Before Writing:** All agents must read specs before generating output.

## Article 4: Code Quality

All changes MUST follow the SDLC TDD discipline:
1. RED test first (proves the defect or gap)
2. GREEN fix (minimal change to pass)
3. Full regression suite (zero regressions)

## Article 5: Branch Governance

GitOps three-tier model:
- `feature/*` → `develop` → `master`
- All merges use `--no-ff` for auditable history
- `master` is the release branch; only `develop` merges into it

## Article 6: Security

Security is not optional. All sandbox isolation mechanisms (VFS, network, env,
identity, GUI passthrough) are security boundaries. Changes to these mechanisms
require documented analysis and full test coverage.

Security vulnerabilities are tracked in `docs/security-bulletins/`.
