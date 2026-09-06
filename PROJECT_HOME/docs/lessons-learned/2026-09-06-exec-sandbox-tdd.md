# Lessons Learned — exec_sandbox() TDD Implementation

## Date: 2026-09-06
## Branch: 0.4.1-a
## Scope: exec_sandbox() mount emission completion

---

## Test Quality Issues Found

### 1. START-EXEC-003: Wrong assertion for isolation property
- **Test:** `START-EXEC-003: host /etc is NOT visible inside sandbox (isolation)`
- **Assertion:** `ls /etc/passwd` should fail (exit != 0)
- **Problem:** Tests a PROXY (file absence) instead of the PROPERTY (host content not visible). Identity injection via `--ro-bind-data 9 /etc/passwd` creates a SYNTHETIC passwd file inside the sandbox. The host's `/etc/passwd` is never exposed. The master monolith has ALWAYS injected `/etc/passwd` — this test would fail against master too.
- **Fix needed:** Test should verify content is synthetic (e.g., `grep sandbox_user /etc/passwd` succeeds, or `wc -l /etc/passwd` shows 1 line, not the host's many lines).
- **Category:** Goodhart's Law — metric (file absence) ceased to measure intent (isolation) when identity injection was added.

### 2. Warning format mismatch (NET-WARN-001, DBUS-WARN-001)
- **Tests expect:** `*"WARNING"*` (SYS-LOG format from master)
- **Implementation used:** `_warn` which emits `[WARN]` (structured log format)
- **Resolution:** Changed to raw `echo "[SYS-LOG] WARNING: ..."` to match both the test expectation AND the master's behavior. These warnings are operational security alerts, not debug logs — the SYS-LOG format is semantically correct.
- **Category:** Format contract — test was right, implementation chose wrong format.

### 3. Exit code contract (MISE-NOBIN-001, MISE-NODATA-001, LBP-MISS-001)
- **Tests expect:** exit 1 (user-correctable configuration error)
- **Implementation used:** `_fatal` which exits 2 (used elsewhere for system errors)
- **Resolution:** Changed to `echo "[FATAL] ..." && exit 1` — exit 1 is correct for "you forgot to install mise" (not a system error).
- **Category:** Exit code semantics — test was right, exit 2 was wrong. Exit 1 = user error, Exit 2 = system/framework error.

## DRY RUN Format Change

- **Old format:** Single-line `[INFO] ... [DRY RUN] bwrap --arg1 --arg2 ...`
- **New format:** Multi-line `[DRY RUN] bwrap\n  --arg1\n  --arg2\n  ...`
- **Why:** Test VFS-REAPPLY-001 uses `grep -n` to verify argument ordering (remount-ro before home-reapply). Single-line format makes all grep matches line 1, breaking positional assertions.
- **Impact:** All 800+ tests using `*"keyword"*` glob matching still work (bats captures all stderr lines into `$output`). Only formatting/banner tests needed review.

## Dependency Ordering Insights

1. **PRE-LOCK vs POST-LOCK is the critical architectural insight.** Any `--dir` or `--bind` that creates a NEW mountpoint must go before `--remount-ro /`. Socket binds into existing tmpfs can go after.
2. **Mise/local-bin are hybrid:** Mount binds go PRE-LOCK but `--setenv PATH` goes POST-LOCK.
3. **Identity injection FD content** must be defined before argv array but `<<<` heredoc goes on the `exec bwrap` line.

## Anti-Patterns Avoided

1. Did NOT make START-EXEC-003 pass by removing identity injection. That would be reward-hacking.
2. Did NOT use `_warn` when the test expected raw SYS-LOG format. Test was correct.
3. Did NOT skip the DRY RUN format change. Single-line format prevented honest ordering verification.
