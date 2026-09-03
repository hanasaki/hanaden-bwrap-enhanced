<!-- (c) 2026-* Frederick Bloom -- PROJECT_HOME/README.md -- Hanaden AI -->

# PROJECT_HOME

This directory is the **virtual filesystem jail root** for the `bwrap-enhanced` sandbox. It provides the structural foundation for the sandbox's isolated environment and houses the project's specification tree, SDLC artifacts, and test suites.

(c) 2026-* Frederick Bloom — All Rights Reserved — Hanaden AI

---

## Canonical Project Documentation

For high-level project documentation, architecture, and governance, refer to the root documents:
* **Project Overview & Quickstart:** [`../README.md`](../README.md)
* **Project Invariants & Constitution:** [`../CONSTITUTION.md`](../CONSTITUTION.md)
* **Custom Dual License:** [`../LICENSE.md`](../LICENSE.md)
* **Legal & Commercial Licensing:** [`docs/legal/`](docs/legal/)

---

## Structure

```
PROJECT_HOME/
├── boot/
│   ├── bwrap-enhanced.sh         # Runtime copy of the sandbox wrapper
│   └── specs/                    # Boot specifications
│       ├── config/               # Configuration specs (####-*.md)
│       ├── cmdstream/            # Command stream specs
│       └── design/               # Design specs
├── docs/
│   ├── legal/                    # Commercial license, CLA, and third-party terms
│   │   ├── FrederickBloom/       # CLA.md & LICENSE-COMMERCIAL.md
│   │   └── third-party/          # AGPL-3.0.txt
│   ├── architecture-design-features-specs/
│   │   └── BwrapEnhanced2026.strat/  # Spec hierarchy tree
│   ├── history/                  # Historical delivery records
│   ├── lessons-learned/          # Post-mortem analyses
│   └── security-bulletins/       # Security advisories
├── generic-sldc-and-engine-readonly/  # SDLC engine spec (read-only)
├── src/
│   ├── main/hanaden-bwrap-enhanced/
│   │   └── bwrap-enhanced.sh     # Source of truth implementation
│   └── test/hanaden-bwrap-enhanced/
│       ├── shared/               # Test framework (assert.sh, env.sh)
│       └── BwrapEnhanced2026.strat/  # Test suites mirroring spec tree
├── CONSTITUTION.md               # Local constitution pointer
└── README.md                     # This file
```

---

## Spec Loading Order

Per AGENTS.md delegation rules, specs MUST be loaded:
1. `boot/specs/config/` — `####-*.md` in numerical sort order
2. `boot/specs/cmdstream/` — `####-*.md` in numerical sort order
3. `boot/specs/design/` — `####-*.md` in numerical sort order

Files with `>= 9000` prefix are meta/reference docs — load on demand only.
