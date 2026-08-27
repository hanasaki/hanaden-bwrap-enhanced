<!-- (c) 2026-* Frederick Bloom -- 20260826-144956-564410-751a-9f5d-0ababdea2ad6-ShebangConvention.spec-0.0.1.md -- Hanaden AI -->
---
filename-id:   20260826-144956-564410-751a-9f5d-0ababdea2ad6-ShebangConvention.spec-0.0.1
node-type:     SPEC
layer:         4
spec-domain:   FUNC
version:       0.0.1
status:        Draft
author:        Frederick Bloom
copyright:     "(c) 2026-* Frederick Bloom"
description: >
  Every bash script MUST use #!/usr/bin/env bash as
  its shebang line.
parent:        20260826-144956-555723-7f72-88ef-6d2f40241d41-BashCodingConventions.feat-0.0.1
leaf-value:    "#!/usr/bin/env bash"
leaf-unit:     "shebang-string"
tdd:
  state:         NOT_STARTED
  test-file:     null
  last-run:      null
  iterations:    0
  coverage-lines: all
---

# ShebangConvention: Every bash script MUST use #!/usr/bin/env bash as

## Specification Statement

Every `.sh` file in the project MUST begin with `#!/usr/bin/env bash` as
its first line. This is the only accepted shebang. Direct paths like
`#!/bin/bash` are prohibited because they fail on systems where bash is not
at `/bin/bash` (e.g., NixOS, some BSDs).

## Rationale

The env-based shebang uses PATH resolution to find bash, making scripts
portable across systems with different bash installation paths.

## Constraints

| Constraint | Value | Condition |
|------------|-------|-----------|
| First line is #!/usr/bin/env bash | Exact match | Every .sh file |
| #!/bin/bash is prohibited | Rejected | Always |

## Leaf Value

> 🛑 **Primitive** — terminal specification.

**Value:** `#!/usr/bin/env bash`

## Measurement Method

```bash
head -1 "$SCRIPT" | grep -qx '#!/usr/bin/env bash' && echo 'PASS' || echo 'FAIL'
```

## Test Suite

> **Suite ID:** PENDING
> **Suite name:** ShebangConvention Spec Suite
> **Test file:** `null` (NOT_STARTED)

### ⚙️ Functional Tests

| ID | Description | Method | Pass Criteria | TDD |
|----|-------------|--------|---------------|-----|
| SHE-001 | Correct shebang accepted | Head check | PASS | NOT_STARTED |
| SHE-002 | #!/bin/bash rejected | Head check | FAIL | NOT_STARTED |
| SHE-003 | Missing shebang rejected | Head check | FAIL | NOT_STARTED |

## References

- SdlcEngineSpec.system-0.0.1

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2026-08-26 | Frederick Bloom + AI | Initial specification |
