---
filename-id: 20260830-040639-917724-7cbe-8320-adfcd5e1c83a-HostRealRootDuplicate.spec-0.3
node-type: SPEC
layer: 4
version: 0.3.0
author: Frederick Bloom
copyright: (c) 2026-* Frederick Bloom
description: "HostRealRootDuplicate behavioral specification"
parent: FlagHostRealRoot
tdd:
  state: GREEN
  test-file: PROJECT_HOME/src/test/hanaden-bwrap-enhanced/suites/FlagHostRealRoot.feat/HostRealRootDuplicate.spec/test_host_real_root_duplicate.bats
---

# HostRealRootDuplicate

## Behavioral Specification

| ID | Description | Verification | TDD State |
|----|-------------|-------------|-----------|
| FHRR-001 | FHRR-DUP-001: --host-real-root twice -> ERROR exit 1 | bats test | GREEN |

## Constraints

- Must conform to parent FEAT contract (FlagHostRealRoot)
- Must pass regression without side effects

## Measurement

- bats-core test assertion pass/fail
- Verified by dry-run output or source analysis

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.3.0 | 2026-08-30 | Frederick Bloom + AI | Initial spec doc |
