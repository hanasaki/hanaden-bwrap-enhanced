<!-- (c) 2026-* Frederick Bloom -- 20260827-000058-068036-700a-97aa-d98358aaa04f-RelativeResourceDiscovery.spec-0.0.1.md -- Hanaden AI -->
---
filename-id:   20260827-000058-068036-700a-97aa-d98358aaa04f-RelativeResourceDiscovery.spec-0.0.1
node-type:     SPEC
layer:         4
spec-domain:   FUNC
version:       0.0.1
status:        Draft
author:        Frederick Bloom
copyright:     "(c) 2026-* Frederick Bloom"
description: >
  Every executable script or program in the project MUST locate project
  resources relative to its own filesystem position. Scripts MUST NOT use
  absolute paths or depend on a specific working directory.
parent:        20260827-000058-047623-715e-acf7-c33b0f61398a-PortabilityEnforcement.feat-0.0.1
leaf-value:    "zero absolute source/assignment paths in executable scripts"
leaf-unit:     "count"
tdd:
  state:         PASS
  test-file:     src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/HostCoupledDevelopment.driv/PortableProjectStructure.moti/PortabilityEnforcement.feat/RelativeResourceDiscovery.spec/test_relative_resource_discovery.sh
  last-run:      null
  iterations:    0
  coverage-lines: all
---

# RelativeResourceDiscovery: Scripts Locate Resources Relative to Self

## Specification Statement

Every executable script or program in the project MUST locate project resources
(shared libraries, configuration, test data) relative to its own filesystem
position. Scripts MUST NOT use absolute paths or depend on a specific working
directory (`$PWD`).

The discovery mechanism is language-specific (implementation detail):
- **Bash:** `BASH_SOURCE[0]` or `$0`
- **Python:** `__file__` or `pathlib.Path(__file__)`
- **Go:** `os.Executable()` or `runtime.Caller(0)`

The REQUIREMENT is language-agnostic: locate resources relative to self.

## Rationale

Absolute paths break on any directory move or machine change. Depending on
`$PWD` breaks when the script is invoked from a different directory. Self-relative
discovery is the only portable pattern.

## Constraints

| ID | Constraint | Condition |
|----|-----------|-----------|
| RRD-C1 | No `source "/absolute/path/..."` in any `.sh` file | Always |
| RRD-C2 | No hardcoded path assignments (e.g., `VAR="/homes/..."`) in scripts | Always |
| RRD-C3 | Scripts use language-appropriate self-location mechanism | Always |

## Leaf Value

> Terminal specification.

**Value:** 0 absolute source/assignment paths in executable scripts
**Source:** Portability requirement

## Measurement Method

```bash
# Check for absolute source lines in all .sh files
find "$WS/PROJECT_HOME/src" -name '*.sh' -exec \
  grep -ln '^source "/' {} \;
# Expected: 0 files
```

## Test Suite

> **Suite ID:** RRD
> **Suite name:** RelativeResourceDiscovery Spec Suite
> **Test file:** `src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/HostCoupledDevelopment.driv/PortableProjectStructure.moti/PortabilityEnforcement.feat/RelativeResourceDiscovery.spec/test_relative_resource_discovery.sh`

### Functional Tests

| ID | Description | Method | Pass Criteria | TDD |
|----|-------------|--------|---------------|-----|
| RRD-001 | Zero absolute source lines | Grep scan of .sh files | 0 matches | PASS |
| RRD-002 | Zero hardcoded path assignments | Grep scan | 0 matches | PASS |

## References

- GenericSdlcEngine WalkUpDiscovery.spec (generic standard)

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2026-08-26 | Frederick Bloom + AI | Initial specification |
