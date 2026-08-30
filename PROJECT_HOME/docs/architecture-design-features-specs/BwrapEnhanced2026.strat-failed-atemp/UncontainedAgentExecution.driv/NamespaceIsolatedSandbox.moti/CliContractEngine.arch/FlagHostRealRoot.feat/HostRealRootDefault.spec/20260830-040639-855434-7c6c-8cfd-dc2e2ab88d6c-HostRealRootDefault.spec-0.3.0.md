---
filename-id: 20260830-040639-855434-7c6c-8cfd-dc2e2ab88d6c-HostRealRootDefault.spec-0.3
node-type: SPEC
layer: 4
version: 0.3.0
author: Frederick Bloom
copyright: (c) 2026-* Frederick Bloom
description: "HostRealRootDefault behavioral specification"
parent: FlagHostRealRoot
tdd:
  state: GREEN
  test-file: PROJECT_HOME/src/test/hanaden-bwrap-enhanced/suites/FlagHostRealRoot.feat/HostRealRootDefault.spec/test_host_real_root_default.bats
---

# HostRealRootDefault

## Behavioral Specification

| ID | Description | Verification | TDD State |
|----|-------------|-------------|-----------|
| FHRR-001 | FHRR-DEF-001: absent --host-real-root -> virtual-roots | bats test | GREEN |

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
