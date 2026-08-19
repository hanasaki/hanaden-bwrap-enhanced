<!-- (c) 2026-* Frederick Bloom -- PUNCHLIST-20260813.md -- Hanaden AI -->
# Complete Validated Punchlist — Rev 2

All outstanding work from the 120-minute session.
Validated against: `git status`, `grep` audits for stale refs, Python leakage, os.execv refs.

---

## Phase 0: Git State Cleanup

- [ ] `git rm --cached config/0050-lang-profile.md` — ghost: staged-added then deleted (renamed to 0045)
- [ ] `git add config/0045-lang-profile.md` — untracked new
- [ ] `git add config/0055-vuniverse-env.md` — untracked new
- [ ] Stage unstaged mods: `config/0100-paths.md`, `design/0000`, test files, cmdstream files

---

## Phase 1: Lang Profile — Remaining Fixes

### 1a. Missing fields in per-lang profiles

- [ ] Add `startup_class` to ALL 5 per-lang profiles (in contract but missing from every profile):

  | File | startup_class |
  |------|--------------|
  | `0050-lang-profile-python.md` | `instant` |
  | `0050-lang-profile-rust.md` | `slow-first` |
  | `0050-lang-profile-rust-script.md` | `moderate` |
  | `0050-lang-profile-go.md` | `moderate` |
  | `0050-lang-profile-zig.md` | `slow-first` |

### 1b. Python leakage in design pseudocode (MISSED in previous punchlist)

**`daemon.py` hardcoded** — must become generic `daemon.<ext>` or use lang profile `filename` token:

| File | Lines | What to fix |
|------|-------|-------------|
| `design/0000` | L79, L98–114 | `daemon.py` → `daemon source (per lang profile filename)` |
| `design/0100-boot-sequence.md` | L253 | `participant D as daemon.py` → `participant D as daemon` |
| `design/0300-inotify-architecture.md` | L101, L104, L129, L138, L149 | `daemon.py`/`daemon_new.py` → generic |
| `design/0400-event-model.md` | L107, L114 | `os.getpid()` → `getpid()` (POSIX) |
| `cmdstream/0200-caller-mode-detection.md` | L41 | `participant D as daemon.py` → `participant D as daemon` |
| `config/0100-paths.md` | L20 | `EPHEMERAL_HOME/daemon.py` → generic |
| `config/0700-toolchain.md` | L24 | `bwrap launches daemon.py` → `bwrap launches the daemon` |

**Python-specific API calls in pseudocode** — must become POSIX-generic or use `(per lang profile)` annotation:

| File | Lines | What to fix |
|------|-------|-------------|
| `design/0300` | L131 | `sys.executable, "-m", "py_compile"` → `syntax_check_cmd (per lang profile)` |
| `design/0300` | L149 | `os.execv(sys.executable, ...)` → `execve(process_replace per lang profile)` |
| `design/0100` | L82, L95 | `os.access(path, os.X_OK)` → `access(path, X_OK)` (POSIX) |
| `design/0500` | L6 | `os.access(MISE_BIN, os.X_OK)` → `access(MISE_BIN, X_OK)` (POSIX) |
| `design/0000` | L79, L134–135 | `os.getpid()`, `os.access()` → POSIX equivalents |
| `design/0400` | L107, L114 | `os.getpid()` → `getpid()` |

### 1c. `os.execv` → `execve` / process_replace

All `os.execv()` references in design specs (12 locations):

| File | Lines |
|------|-------|
| `design/0000` | L79, L165 |
| `design/0100` | L118 |
| `design/0300` | L99, L106, L119, L120, L149, L151 |
| `design/0400` | L101 |
| `design/0900` | L10, L11 |

### 1d. Stale `0050-lang-profile.md` reference

- [ ] `design/0000` L31: `config/0050-lang-profile.md` → `config/0045-lang-profile.md`

---

## Phase 2: Vuniverse System

### 2a. Update existing `config/0055-vuniverse-env.md`

- [ ] Add `[toolchain]` section — tools required inside vuniverse (mise, rtk, uv), verification at boot
- [ ] Fix stale ref to `config/0100-paths.md` → `config/0060-vuniverse-fs.md`
- [ ] Fix stale ref to `config/0700-toolchain.md` → remove (absorbed into `[toolchain]`)

### 2b. Backend profile system (9 NEW files)

- [ ] `config/0058-vuniverse-backend.md` — general: backends_allowed (dev/prod), backend_choice (locked/ai-choice/first-available), profile contract
- [ ] `config/0058-vuniverse-backend-bwrap-enhanced.md` — full profile + rationale + constraints + `[anti_regression]`
- [ ] `config/0058-vuniverse-backend-bwrap.md` — stub
- [ ] `config/0058-vuniverse-backend-docker.md` — stub
- [ ] `config/0058-vuniverse-backend-podman.md` — stub
- [ ] `config/0058-vuniverse-backend-firejail.md` — stub
- [ ] `config/0058-vuniverse-backend-gvisor.md` — stub
- [ ] `config/0058-vuniverse-backend-nspawn.md` — stub

### 2c. Vuniverse filesystem (1 NEW, replaces `0100-paths`)

- [ ] `config/0060-vuniverse-fs.md`:
  - EPHEMERAL_HOME formula + parts
  - `[mounts]` TOML — all bind mounts as SST
  - `[mounts.tokens]` — token resolution (MISE_BIN, MISE_DATA_DIR, etc.)
  - Interior layout diagram + mermaid (from design/0000 L139–162)
  - /tmp constraint (from design/0000 L105–114)
  - Missing mounts: mise installs, downloads, config
  - Dev/prod overrides (ro/rw per mount)
  - Pre-seed commands

### 2d. Agent session env (1 NEW)

- [ ] `config/0070-ai-agent-env.md`:
  - `[toolchain]` — host-side mise/rtk/uv resolution
  - `[session]` — mise activate, rtk prefix
  - `[sidecar]` — sidecar spinup from host side

---

## Phase 3: Service Controller Design Spec (1 NEW)

- [ ] `design/1000-service-controller.md`:
  - `boot/hanaden-daemon` script design
  - Commands: `{start|forcestart|stop|restart|forcerestart|reload|force-reload|status|list-backends|list-langs}`
  - POSIX CLI params: `-b/--backend`, `-l/--lang`, `-e/--env`, `-c/--conv-id`, `-d/--daemon-source`, `-p/--project-home`, `-f/--foreground`, `-v/--verbose`, `-q/--quiet`, `-h/--help`, `-V/--version`
  - Env var equivalents + priority chain (CLI → env → config → fallback)
  - PID management (double PID: host backend + daemon inside vuniverse)
  - Signal routing (SIGTERM → backend → daemon)
  - LSB exit codes (0/1/2/3/4)
  - Version output: `hanaden-daemon 0.0.1`
  - Banner header: `Copyright (c) 2026 Hanaden - Frederick Bloom`
  - Help output format
  - `list-backends` probe output
  - `list-langs` probe output
  - `boot/vuniverse.sh` launcher design
  - Launch manifest format (key=value)
  - systemd unit template (`hanaden-daemon@.service`)
  - Reboot vs self-regen: daemon preserves argv/envp, no runner needed for regen

---

## Phase 4: DRY Cleanup

### 4a. Strip `design/0000-frontmatter-identity.md` (~100 lines)

- [ ] Remove L64–165: EPHEMERAL_HOME details, bwrap invocation, /tmp constraint, rationale, layout diagram, mermaid
- [ ] Add pointer: EPHEMERAL_HOME → `config/0060-vuniverse-fs.md`
- [ ] Add pointer: Vuniverse → `config/0055-vuniverse-env.md`
- [ ] Add pointer: Backend → `config/0058-vuniverse-backend.md`
- [ ] Fix L31: `config/0050` → `config/0045`

### 4b. Clean `design/0900-anti-regression.md`

- [ ] Remove L15–17 (bwrap mandates) → `0058-vuniverse-backend-bwrap-enhanced.md [anti_regression]`
- [ ] Add pointer: "Backend-specific mandates → backend profile"
- [ ] Update L10–11: `os.execv()` → generic (per Phase 1c)

### 4c. Clean `design/0500-ai-standing-rules.md`

- [ ] L6: `os.access(MISE_BIN, os.X_OK)` → `access(MISE_BIN, X_OK)` (POSIX)
- [ ] L6–7: `--ro-bind at boot` → reference backend profile

### 4d. Delete absorbed files

- [ ] Delete `config/0100-paths.md` → absorbed into `config/0060-vuniverse-fs.md`
- [ ] Delete `config/0700-toolchain.md` → split into `0055 [toolchain]` + `0070 [toolchain]`

### 4e. Update all cross-references

- [ ] `config/0055-vuniverse-env.md`: refs `0100-paths.md` → `0060-vuniverse-fs.md`
- [ ] `config/0055-vuniverse-env.md`: refs `0700-toolchain.md` → remove
- [ ] `design/0000`: refs `config/0050-lang-profile.md` → `config/0045`
- [ ] Global grep: any remaining `0100-paths` → `0060-vuniverse-fs`
- [ ] Global grep: any remaining `0700-toolchain` → vuniverse-env / ai-agent-env
- [ ] Global grep: any remaining `0050-lang-profile.md` (the general one) → `0045`

### 4f. Config frontmatter update

- [ ] `config/0000-config-frontmatter.md` — may need to add entries for new vuniverse/backend files if it maintains a file registry

---

## Phase 5: Verification + Commits

### Grep audits

- [ ] No stale refs to deleted/renamed files (0050-lang-profile.md, 0100-paths, 0700-toolchain)
- [ ] No `daemon.py` outside lang profiles and meta docs (≥9000)
- [ ] No Python API (`os.access`, `os.execv`, `sys.executable`, `os.rename`, `os.getpid`) outside lang profiles — pseudocode uses POSIX equivalents
- [ ] No bwrap-specific content outside backend profiles and pseudocode
- [ ] Every per-lang profile has ALL required contract fields (including startup_class)

### Commits (3 clean commits)

- [ ] **Commit 1**: Lang profile — Phase 0 + Phase 1 (fixes, startup_class, Python leakage, execve)
- [ ] **Commit 2**: Vuniverse system — Phase 2 + Phase 3 (vuniverse env/fs/backend, agent-env, service controller spec)
- [ ] **Commit 3**: DRY cleanup — Phase 4 (strip 0000, clean 0900/0500, delete 0100/0700, cross-refs)

---

## Summary

| Phase | Description | File ops | Status |
|-------|------------|:-------:|--------|
| 0 | Git state cleanup | 4 | 0% |
| 1 | Lang profile fixes + Python leakage + execve | ~17 edits | 80% (profiles exist, need fixes) |
| 2 | Vuniverse system | 12 new/edit | 15% (0055 exists) |
| 3 | Service controller spec | 1 new | 0% |
| 4 | DRY cleanup | ~10 edit + 2 delete | 0% |
| 5 | Verification + commits | audits + 3 commits | 0% |
| **Total** | | **~50 ops** | |
