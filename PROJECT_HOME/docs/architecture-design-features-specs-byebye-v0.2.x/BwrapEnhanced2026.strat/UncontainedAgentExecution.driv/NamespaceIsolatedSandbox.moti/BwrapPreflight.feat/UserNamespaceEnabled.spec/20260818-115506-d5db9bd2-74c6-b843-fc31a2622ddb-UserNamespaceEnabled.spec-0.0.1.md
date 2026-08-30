<!-- (c) 2026-* Frederick Bloom -- 20260818-115506-d5db9bd2-74c6-b843-fc31a2622ddb-UserNamespaceEnabled.spec-0.0.1.md -- Hanaden AI -->
---
filename-id:   20260818-115436-d5db9bd2-74c6-b843-fc31a2622ddb-UserNamespaceEnabled.spec
node-type:     SPEC
layer:         4
version:       0.0.1
status:        Implemented
parent:        20260818-115436-3cae04ea-7ac9-bf0b-6b05561a8450-BwrapPreflight.feat
tdd:
  test-file:      src/test/hanaden-bwrap-enhanced/BwrapEnhanced2026.strat/UncontainedAgentExecution.driv/NamespaceIsolatedSandbox.moti/BwrapPreflight.feat/UserNamespaceEnabled.spec/test_user_namespace_enabled.sh
---
# UserNamespaceEnabled Spec
## Constraint Table
| ID | Constraint | Severity |
|----|-----------|----------|
| C1 | `/proc/sys/kernel/unprivileged_userns_clone` = 1 OR kernel allows user ns by default | FATAL |
| C2 | `unshare -U /bin/true` exits 0 | FATAL |
## Measurement Method
```bash
val=$(cat /proc/sys/kernel/unprivileged_userns_clone 2>/dev/null || echo "1")
[[ "$val" == "1" ]] || unshare -U /bin/true
```
