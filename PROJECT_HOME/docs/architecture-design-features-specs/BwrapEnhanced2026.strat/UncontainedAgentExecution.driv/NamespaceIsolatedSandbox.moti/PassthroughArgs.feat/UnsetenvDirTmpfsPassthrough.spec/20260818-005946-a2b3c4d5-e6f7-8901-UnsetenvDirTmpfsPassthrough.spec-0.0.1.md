<!-- (c) 2026-* Frederick Bloom -- 20260818-005946-a2b3c4d5-e6f7-8901-UnsetenvDirTmpfsPassthrough.spec-0.0.1.md -- Hanaden AI Loader -->
---
filename-id:   20260818-005946-a2b3c4d5-e6f7-8901-UnsetenvDirTmpfsPassthrough.spec
node-type:     SPEC
layer:         4
spec-domain:   FUNC
version:       0.0.1
status:        Implemented
author:        Frederick Bloom
copyright:     (c) 2026-* Frederick Bloom
description: >
  The CLI parser MUST accept --unsetenv, --dir, --tmpfs, and --symlink as
  passthrough flags, forwarding them verbatim into BWRAP_PASSTHROUGH_ARGS.
  --unsetenv takes 1 arg; --dir, --tmpfs, --symlink take 2 args each.
  An unknown flag (-*) MUST print FATAL ERROR and call usage() with exit 1.
  A bare -- separator MUST shift and assign remaining args to TARGET_CMD.
  A non-flag word MUST assign it and all remaining args to TARGET_CMD.
parent:        20260816-182145-PassthroughArgs.feat
leaf-value:    "--unsetenv(1 arg) --dir/--tmpfs/--symlink(2 args) → BWRAP_PASSTHROUGH_ARGS; unknown → FATAL"
leaf-unit:     "CLI parse + BWRAP_PASSTHROUGH_ARGS append"
tdd:
  state:          PASS
  test-file:      src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/UncontainedAgentExecution.driv/NamespaceIsolatedSandbox.moti/PassthroughArgs.feat/UnsetenvDirTmpfsPassthrough.spec/test_unsetenv_dir_tmpfs_passthrough.sh
  last-run:       2026-08-18T16:08:59Z
  iterations:     1
  coverage-lines: "L780-L787"
---

# UnsetenvDirTmpfsPassthrough: --unsetenv, --dir, --tmpfs, --symlink, --, and Unknown Flag Handling

## Specification Statement

The CLI parser (while/case loop) MUST handle the following additional patterns:

- `--unsetenv VAR` → `BWRAP_PASSTHROUGH_ARGS+=(--unsetenv VAR)` (1 argument)
- `--dir PATH` → `BWRAP_PASSTHROUGH_ARGS+=(--dir PATH)` (2 arguments)
- `--tmpfs PATH` → `BWRAP_PASSTHROUGH_ARGS+=(--tmpfs PATH)` (2 arguments)
- `--symlink TARGET LINK` → `BWRAP_PASSTHROUGH_ARGS+=(--symlink TARGET LINK)` (2 arguments — same 3-word pattern as bind)
- `-h|--help` → calls `usage()` which exits 1
- `--` → shift; assign all remaining args to `TARGET_CMD`; break
- `-*` (any unrecognized flag) → print `FATAL ERROR: Unknown option '$1'` to stdout; call `usage()` which exits 1
- `*` (non-flag word) → assign `$@` to `TARGET_CMD`; break

## Rationale

bwrap natively supports `--unsetenv`, `--dir`, `--tmpfs`, and `--symlink`. Callers
building layered sandbox configurations need to pass these through without having to
know the internal bwrap_args construction. The 3-argument forms (TARGET LINK for
--symlink) share the same `shift 3` pattern as bind args. The `--unsetenv` flag
takes only 1 additional arg (the env var name), so it uses `shift 2`.

The unknown-flag trap (`-*`) provides fail-fast semantics: a typo like `--enble-audio`
immediately aborts with a clear message rather than silently ignoring the flag.

The `--` separator follows POSIX convention for end-of-options, allowing CMD args
that begin with `-` to be passed safely.

## Constraints

| Constraint | Value | Condition |
|------------|-------|-----------|
| --unsetenv VAR | appended to BWRAP_PASSTHROUGH_ARGS (shift 2) | Always |
| --dir PATH | appended to BWRAP_PASSTHROUGH_ARGS (shift 2) | Always |
| --tmpfs PATH | appended to BWRAP_PASSTHROUGH_ARGS (shift 2) | Always |
| --symlink TARGET LINK | appended to BWRAP_PASSTHROUGH_ARGS (shift 3) | Always |
| -h / --help | calls usage(), exits 1 | Always |
| -- | shifts, assigns $@ to TARGET_CMD, breaks | Always |
| -* unknown | FATAL ERROR on stdout + usage() + exit 1 | Unrecognized flag |
| * non-flag | assigns $@ to TARGET_CMD, breaks | Non-flag first arg |

## Leaf Value

> 🛑 **Primitive** — terminal specification.

**Value:** 4 passthrough flag types + 4 exit/break patterns in CLI parser case statement
**Source:** bwrap-enhanced.sh L780-L787

## Measurement Method

```bash
# --unsetenv passthrough:
./bwrap-enhanced.sh --unsetenv TERM -- /bin/true 2>&1
# Expected: exit 0 (bwrap receives --unsetenv TERM)

# --dir passthrough:
./bwrap-enhanced.sh --dir /tmp/probe -- /bin/true 2>&1
# Expected: exit 0 (bwrap creates /tmp/probe dir in sandbox)

# --tmpfs passthrough:
./bwrap-enhanced.sh --tmpfs /srv -- /bin/true 2>&1
# Expected: exit 0 (bwrap creates tmpfs at /srv)

# Unknown flag:
./bwrap-enhanced.sh --enble-audio -- /bin/true 2>&1; echo "exit: $?"
# Expected: "FATAL ERROR: Unknown option '--enble-audio'" on stdout; exit != 0

# -- separator:
./bwrap-enhanced.sh -- bash -c 'echo ok'
# Expected: "ok" printed; bash is TARGET_CMD

# Non-flag word:
./bwrap-enhanced.sh /bin/true
# Expected: /bin/true runs as TARGET_CMD; exit 0
```

## Test Suite

> **Suite ID:** 20260818-005946-a2b3c4d5-e6f7-8901-UnsetenvDirTmpfsPassthrough.spec-SUITE

### ⚙️ Functional Tests

| ID | Description | Method | Pass Criteria | TDD |
|----|-------------|--------|---------------|-----|
| UDTP-001 | --unsetenv forwarded | `--unsetenv TERM -- /bin/true` | exit 0 | NOT_STARTED |
| UDTP-002 | --dir forwarded | `--dir /tmp/probe -- bash -c 'test -d /tmp/probe'` | exit 0 | NOT_STARTED |
| UDTP-003 | --tmpfs forwarded | `--tmpfs /srv -- bash -c 'mount \| grep /srv'` | tmpfs at /srv | NOT_STARTED |
| UDTP-004 | --symlink forwarded | `--symlink /usr/bin /bin2 -- bash -c 'test -L /bin2'` | symlink exists | NOT_STARTED |
| UDTP-005 | -- separator ends args | `-- bash -c 'echo ok'` | "ok" | NOT_STARTED |
| UDTP-006 | Non-flag = TARGET_CMD | `/bin/true` (no --) | exit 0 | NOT_STARTED |
| UDTP-007 | Unknown flag = FATAL | `--badopt -- /bin/true` | exit != 0 + FATAL ERROR msg | NOT_STARTED |
| UDTP-008 | --help exits 1 | `-h` | exit 1 + usage printed | NOT_STARTED |

## References

- bwrap-enhanced.sh L780-L787 (case statement: --unsetenv, --dir, --tmpfs, --symlink, -h, --, -*, *)
- BindPassthrough.spec (sibling: --ro-bind/--bind/--setenv patterns)

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2026-08-18 | Frederick Bloom + AI | Initial spec — reverse-engineered from bwrap-enhanced.sh L780-L787 |
