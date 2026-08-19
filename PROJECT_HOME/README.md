<!-- (c) 2026-* Frederick Bloom -- PROJECT_HOME/README.md -- Hanaden AI -->

# PROJECT_HOME

This directory is the **virtual filesystem jail root** for the bwrap-enhanced sandbox.
It provides the structural foundation for the sandbox's isolated environment.

(c) 2026-* Frederick Bloom — All Rights Reserved — Hanaden AI

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
│   ├── architecture-design-features-specs/
│   │   └── BwrapEnhanced2026.strat/  # Spec hierarchy tree
│   ├── history/                  # Historical delivery records
│   ├── lessons-learned/          # Post-mortem analyses
│   └── security-bulletins/       # Security advisories
├── generic-sldc-and-engine-readonly/  # SDLC engine spec (read-only)
├── src/
│   ├── main/hanaden-bwrap-enhanced/
│   │   └── bwrap-enhanced.sh     # Source of truth
│   └── test/hanaden-bwrap-enhanced/
│       ├── shared/               # Test framework (assert.sh, env.sh)
│       └── BwrapEnhanced2026.strat/  # Test suites mirroring spec tree
├── CONSTITUTION.md               # Project governance
└── README.md                     # This file
```

## Spec Loading Order

Per AGENTS.md delegation rules, specs MUST be loaded:
1. `boot/specs/config/` — `####-*.md` in numerical sort order
2. `boot/specs/cmdstream/` — `####-*.md` in numerical sort order
3. `boot/specs/design/` — `####-*.md` in numerical sort order

Files with `>= 9000` prefix are meta/reference docs — load on demand only.
