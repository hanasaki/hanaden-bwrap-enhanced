# Run Report — exec_sandbox() TDD Implementation

## Summary

| Metric | Run 1 (baseline) | Run 2 (impl v1) | Run 3 (impl v2) |
|:---|:---:|:---:|:---:|
| **Date** | 2026-09-06 07:32 | 2026-09-06 08:19 | 2026-09-06 08:28 |
| **Total tests** | 875 | 875 | 875 |
| **Passed** | 816 | 867 | **874** |
| **Failed** | **59** | **8** | **1** |
| **Pass rate** | 93.2% | 99.1% | **99.89%** |
| **Duration** | 261s | 273s | 259s |
| **JSONL** | `20260906-073228` | `20260906-081943` | `20260906-082814` |

---

## Run 3 — Final Status (874/875)

### Remaining Failure

| Test ID | Description | Root Cause |
|:---|:---|:---|
| START-EXEC-003 | host /etc is NOT visible inside sandbox | **Poorly written test.** Asserts `ls /etc/passwd` fails. Identity injection creates synthetic `/etc/passwd` via `--ro-bind-data 9`. This is CORRECT behavior (master does it too). Test should verify CONTENT is synthetic, not that file is absent. |

### What was fixed (59 → 1)

| Category | Tests Fixed | What Changed |
|:---|:---:|:---|
| Namespace flags | 3 | Added `--unshare-user`, `--hostname`, `--as-pid-1` |
| /etc skeleton + ro-binds | 7 | Added `--dir /etc` + 20+ selective `--ro-bind-try` |
| Device + tmpfs | 3 | `--dev-bind /dev /dev`, `--tmpfs /dev/shm`, `/run/user/UID` |
| Identity injection | 6 | `--ro-bind-data` FD9/10/11 + `--tmpfs /etc/profile.d` |
| Host shadowing | 2 | Covered by identity injection |
| Shared data | 3 | `/usr/share`, fontconfig, `/opt/google` |
| Env vars | 2 | `XDG_DATA_HOME`, `XDG_STATE_HOME` |
| remount-ro + home | 2 | `--remount-ro /` + home re-bind + DRY RUN format fix |
| X11 | 3 | Socket bind + `DISPLAY` + `XAUTHORITY` |
| Wayland | 2 | Socket bind + `WAYLAND_DISPLAY` |
| Audio | 2 | PipeWire + PulseAudio sockets |
| A11y | 1 | AT-SPI bus bind |
| D-Bus | 2 | Session bus + WARNING format |
| GNOME | 3 | gvfs + dconf + keyring |
| KDE | 2 | kwallet + KSMserver |
| Implication chains | 3 | Handled by resolved `$x11` flag |
| Mise | 7 | Full passthrough + validation + PATH |
| Local-bin | 3 | ro/rw bind + validation |
| Net warning | 1 | SYS-LOG WARNING format |
| Home-parent | 1 | `$home_parent` wired into binds |
| Error format | 1 | `[DIAG]` + `[HINT]` tags |
| **Total** | **58** | |

### Duration Breakdown

All runs use `--timed` with `--jobs` auto-calculated (25% of cores).

- Run 1: 261s (4.35 min)
- Run 2: 273s (4.55 min) — slightly slower due to longer dry-run output parsing
- Run 3: 259s (4.32 min) — optimized output format

### Code Changes

- **File:** `bwrap-enhanced.sh` in worktree `0.4.1-a`
- **Function:** `exec_sandbox()` — expanded from 70 lines to ~270 lines
- **Net new code:** ~200 lines (conditional mount blocks, FD injection, env vars)
- **New helpers:** 0 (reused `_warn`, `_fatal`, `_error`, `_info`)
- **Format changes:** DRY RUN output to multi-line, error diagnostics to `[DIAG]`+`[HINT]`
- **Tests modified:** 0

### Test Quality Issues Uncovered

1. **START-EXEC-003** — Wrong proxy assertion (documented in lessons-learned)
2. **Warning format** — Tests correctly expected SYS-LOG format; impl incorrectly used structured log
3. **Exit codes** — Tests correctly expected exit 1; impl incorrectly used exit 2

## JSONL Report Paths

```
PROJECT_HOME/target/test.run.report/20260906-073228-821664.run-all.test.run/streaming.jsonl  # baseline
PROJECT_HOME/target/test.run.report/20260906-081943-202785.run-all.test.run/streaming.jsonl  # impl v1
PROJECT_HOME/target/test.run.report/20260906-082814-313070.run-all.test.run/streaming.jsonl  # impl v2 (final)
```
