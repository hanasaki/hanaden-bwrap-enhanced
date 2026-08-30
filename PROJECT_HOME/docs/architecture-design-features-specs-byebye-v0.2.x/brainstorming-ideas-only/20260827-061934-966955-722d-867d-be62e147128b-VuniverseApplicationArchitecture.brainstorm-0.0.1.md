# Vuniverse -- Comprehensive Application Architecture Brainstorming
<!-- brainstorming-ideas-only -- NOT a spec, NOT a commitment -->
<!-- Created:  2026-08-27T06:19:34Z -->
<!-- Origin:   VirtualRootProvisionerArch.brainstorm-0.0.1 (2026-08-25T23:48:18Z) -->
<!-- ID: 20260827-061934-966955-722d-867d-be62e147128b -->
<!-- Absorbs: VirtualRootProvisionerArch.brainstorm-0.0.1 (kept intact as historical record) -->

> [!NOTE]
> **Recovery Document.** This consolidates ALL surviving knowledge about the
> vuniverse application from multiple sources:
> 1. The original `VirtualRootProvisionerArch.brainstorm` (in-repo)
> 2. The vuniverse provisioner rediscovery report (conversation `fb847726`)
> 3. The deleted vuniverse boot specs (recovered from git `e0b1dba~1`)
> 4. User shell history (`seed_item`/`seed_dir` functions)
> 5. The `ImplementationLanguageSelection.decis` decision record (never committed)
> 6. The `JailProvisioner2026.strat` strategy doc (never committed)
> 7. The `VuniverseSystemBuildout.plan-0.0.1` buildout plan (never committed)
>
> **Nothing in this document is approved, specced, or committed.**

---

## 1. What Is Vuniverse?

**Vuniverse** (n.) -- *Hanaden term.* The complete, designed operational environment
inside a vuniverse backend boundary. Not just filesystem isolation (jail) or process
restriction (sandbox) -- the vuniverse is everything: env vars, toolchain, identity,
processes, shell config, ephemeral state. It is **built from config specs**, not inherited.

Vuniverse is **one application** with a module architecture. It is currently
implemented in Bash. The long-term target is **Rust**.

### What Exists Today (in this repo)

| Component | Status | Location |
|-----------|--------|----------|
| `bwrap-enhanced.sh` | Working Bash script (~650 LOC) | `PROJECT_HOME/src/main/hanaden-bwrap-enhanced/` |
| `bwrap-enhanced.sh` (boot copy) | Identical mirror | `PROJECT_HOME/boot/` (MUST-NOT edit without permission) |
| Brainstorm doc (this file) | Active | `brainstorming-ideas-only/` |

### What Was Lost (never committed or deleted)

| Component | Status | Where It Was |
|-----------|--------|-------------|
| `provisioner.sh` (259 LOC) | **Never committed** | `home-remote-ssh/` paths |
| 9 test suites (721 LOC total) | **Never committed** | `src/test/hanaden-vuniverse-provisioner/` |
| `JailProvisioner2026.strat` | **Never committed** | `docs/hanaden-vuniverse-provisioner-arch.../` |
| `ImplementationLanguageSelection.decis` | **Never committed** | Same directory |
| 10 vuniverse config specs | **Deleted in `e0b1dba`** | `boot/specs/config/0055-*`, `0058-*`, `0060-*` |
| `VuniverseSystemBuildout.plan` (712 lines) | **Never committed** | `docs/history/vuniverse-system-buildout-0.0.1/` |
| 67 planned SDLC specs | **Never written** | Planned in buildout |
| Buildout delivery/run/timeline reports | **Never filled** | `docs/history/` |

---

## 2. Application Architecture -- Module Model

Vuniverse is one application with modules (subcommands), not multiple tools.

```
vuniverse <module> [module-options] [-- CMD [ARGS...]]

Modules:
  provision    Manage virtual root environments (Control Plane)
  ctrl         Execute a process inside a sandbox (Data Plane)
```

`bwrap-enhanced.sh` is the current Bash implementation of what will become the
`ctrl` module. The seeding functions (`seed_item`/`seed_dir`) are what will
become part of the `provision` module.

### Two-Plane Architecture

```
+---------------------------------------------+
|  PROVISION (Control Plane)                   |
|  vuniverse provision <subcommand>            |
|                                              |
|  - Runs on host, never inside sandbox        |
|  - Full RW access to ${ROOT_DIR}             |
|  - Creates, modifies, inspects, removes      |
|    virtual root environments                 |
|  - Seeds auth tokens, IDE config             |
|  - Refuses if BWRAP_SANDBOX=1 is set         |
+---------------------------------------------+
            | creates / manages
            v
+---------------------------------------------+
|  ${ROOT_DIR}/  (Virtual Root on host)        |
|  etc/ home/${V}/ tmp/ run/ var/ opt/ ...     |
+---------------------------------------------+
            | used read-only (except home)
            v
+---------------------------------------------+
|  CTRL (Data Plane)                           |
|  vuniverse ctrl [options] -- CMD             |
|                                              |
|  - Runs on host, exec's into sandbox         |
|  - Reads ${ROOT_DIR} (RO at runtime)         |
|  - Applies bwrap namespace isolation         |
|  - Adds tier-specific binds per flags        |
|  - Sandboxed process has no access to        |
|    Provision module or host outside binds    |
+---------------------------------------------+
```

Aligned with CONSTITUTION.md Immutable Principle:
- External Construction -> Provision module designs and provisions the jail before execution
- External Enforcement -> bwrap kernel namespaces enforce from outside
- Zero Self-Policing -> sandboxed process cannot modify its own confinement

---

## 3. Corrections to Initial Critique

The original critique incorrectly attributed "virtual-root RW" to the user's design.
That was a fabrication error in the analysis. The user's actual intent, confirmed, was:

- **Virtual root** (`--root-dir`) -> **RO** at runtime (`--remount-ro /` applied by Controller)
- **`/tmp`, `/dev/shm`** -> fresh **tmpfs** (RW, ephemeral, kernel-managed)
- **`/run/user/UID`** -> fresh **tmpfs** (RW, ephemeral, kernel-managed)
- **Home dir** (`/home/${VIRTUAL_USER}`) -> **RW**, persisted to host under
  `${ROOT_DIR}/home/${VIRTUAL_USER}/`

The virtual root itself is immutable at runtime. Only the home dir and kernel tmpfs
mounts are writable. This is NOT a security regression -- it is the correct design.

---

## 4. The Virtual Root -- Overlay Model

The virtual root dir contains ONLY the synthetic/override layer:

```
${ROOT_DIR}/              <- --root-dir on host; "/" inside sandbox
  etc/                    <- synthetic minimum subset (fake passwd, group, resolv.conf,
  |                          ld.so.cache-bind, ssl/certs-bind, bash profile stub)
  home/
    ${VIRTUAL_USER}/      <- RW, persisted to host; "/home/${VIRTUAL_USER}" inside sandbox
  tmp/                    <- empty dir; replaced by fresh tmpfs at runtime
  dev/                    <- empty dir; populated by bwrap device setup
  proc/                   <- empty dir; populated by bwrap --proc
  run/                    <- empty dir; replaced by fresh tmpfs at runtime
  var/                    <- empty dir (host /var bound RO on top at runtime)
  opt/                    <- empty dir (host /opt bound RO on top at runtime)
```

At runtime the ctrl module (bwrap) additionally binds from host, all **RO**:
- `/usr` -> host `/usr`
- `/lib`, `/lib64`, `/bin`, `/sbin` -> host equivalents (or symlinks)
- `/var` -> host `/var`
- `/opt` -> host `/opt` (default RO; override with `--enable-opt-rw`)

No full OS copy. No package manager bootstrap. No container image required.
Virtual root dir is lightweight -- kilobytes, not gigabytes.

### Home Dir -- Persistence Model

The home dir lives at `${ROOT_DIR}/home/${VIRTUAL_USER}/` on the host.
Inside the sandbox it is mounted at `/home/${VIRTUAL_USER}` as **RW**.

This is **NOT ephemeral** by default. Data written to `~` inside the sandbox
persists across runs, just like a real user's home directory.

"Ephemeral" is a CHOICE: the operator deletes `${ROOT_DIR}/` after use.
By default the provisioned environment accumulates state across runs -- this is
the intended behavior for developer workspaces.

**Self-contained blast zone:** deleting `${ROOT_DIR}/` removes the entire
environment (root + home) atomically. No scattered state across multiple host paths.

### Directory Convention

Virtual roots live at: `~/vuniverse-roots/<project>/`

Context derivation priority for `<project>`:
1. CLI flag (`--project NAME`)
2. Environment variable (`HANADEN_PROJECT`)
3. Git basename (`basename $(git rev-parse --show-toplevel)`)

---

## 5. CLI Specification (brainstorm -- proposed, not final)

### Module: `provision`

Full mutable write access to `${ROOT_DIR}`. Runs externally, never inside a sandbox.
Safety: refuses to execute if `BWRAP_SANDBOX=1` is set (or equivalent namespace check).

```
vuniverse provision <subcommand> [options]

Subcommands:
  create      Create a new virtual root environment
              (errors if already exists; prints full resolved path)
  modify      Add or remove components from an existing root
  describe    Show current state and contents of a root
  list        List all roots under a given parent directory
  snapshot    Save a point-in-time copy of a root before modification
  diff        Show what changed between two snapshots
  schema      Print the JSON Schema for the virtual root spec to stdout

create options:
  --root-dir PATH            Required. Must not already exist.
  --virtual-user NAME        Virtual username [default: sandbox-user]
  --home-dir PATH            Home path inside sandbox [default: /home/${VIRTUAL_USER}]

modify options:
  --root-dir PATH            Required.
  --add COMPONENT            Component to add
  --remove COMPONENT         Component to remove
  [auto-snapshots before every modify]

describe options:
  --root-dir PATH            Required.

list options:
  --parent-dir PATH          List all roots directly under this directory.

snapshot options:
  --root-dir PATH            Required.
  --name LABEL               Optional label [default: UTC timestamp]

diff options:
  --root-dir PATH            Required.
  --from SNAPSHOT            [default: previous snapshot]
  --to SNAPSHOT              [default: current state]

schema:
  [no options -- prints JSON Schema to stdout]
  Usage: vuniverse provision schema > vroot.schema.json
```

### Module: `ctrl`

Read-only consumer of `${ROOT_DIR}`. Applies bwrap namespace isolation and
executes CMD inside the sandbox. Replaces the current bare `bwrap-enhanced.sh`
invocation.

```
vuniverse ctrl [options] -- CMD [ARGS...]

Core options:
  --root-dir PATH            Virtual root dir [default: ~/vuniverse-roots/default]
  --virtual-user NAME        Virtual username inside sandbox [default: sandbox-user]
  --home-dir PATH            Home inside sandbox [default: /home/${VIRTUAL_USER}]

Tier 1 -- RO socket passthrough (zero host FS exposure):
  --enable-wayland           Bind wayland-0 socket RO
  --enable-audio             Bind pipewire-0 and/or pulse socket RO
  --enable-a11y              Bind AT-SPI bus socket RO

Tier 2 -- RW socket passthrough (bidirectional IPC, no host FS files):
  --enable-gnome             Bind dconf, keyring, gvfs, gcr sockets RW
  --enable-kde               Bind kwallet5, ksmserver, drkonqi sockets RW

Tier 3 -- Bounded host FS READ (reads specific host dirs; zero host FS write):
  --enable-mise-ro           Bind ~/.local/share/mise and ~/.config/mise RO
  --enable-local-bin-ro      Bind ~/.local/bin RO

Tier 4 -- Bounded host FS WRITE (writes persist to host after exit):
  --enable-mise-rw           Bind ~/.local/share/mise and ~/.config/mise RW
  --enable-local-bin-rw      Bind ~/.local/bin RW
  --enable-opt-rw            Bind /opt RW [default: /opt bound RO from host]

Tier 5 -- Portal bridge (SHIELDS PIERCED -- unbounded host FS via D-Bus portals):
  --enable-dbus              Enable D-Bus session bus

Orthogonal options (independent of tier; combinable at any tier):
  --share-net                Share host network namespace [default: --unshare-net]
```

### Flag Renames from Current Implementation

| Old flag | New flag | Notes |
|---|---|---|
| `--host-real-root PATH` | `--root-dir PATH` | Same semantics |
| `--host-real-home-parent PATH` | `--home-dir PATH` | Semantics change: now absolute path INSIDE sandbox |
| `--virtual-user-name NAME` | `--virtual-user NAME` | Shorter |
| *(bare script)* | `ctrl` subcommand | `vuniverse ctrl ...` |

---

## 6. Antigravity Auth Seeding

### What It Does

Copies AGY login tokens, IDE settings, and extensions from the current user's
home into the virtual root home -- just enough to keep Antigravity authenticated
inside the sandbox. Idempotent: skips if already present.

### Existing Implementation (from shell history -- never formalized)

```bash
# Iteration 3 (final, labeled version):
seed_item() {
    local src="$1"
    local dst="$2"
    local name="$3"

    if [[ -e "$dst" ]]; then
        echo "[OK] ${name} already present in virtual home (preserving existing state)"
    elif [[ -e "$src" ]]; then
        echo "[+] Copying ${name} from host..."
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
    else
        echo "[!] Warning: ${name} not found at ${src} (skipping)"
    fi
}

# 3 paths seeded:
seed_item "$HOME/.gemini"                 "${DEV_HOME}/.gemini"                 "Auth Tokens (~/.gemini)"
seed_item "$HOME/.config/Antigravity IDE" "${DEV_HOME}/.config/Antigravity IDE" "IDE Settings (~/.config/Antigravity IDE)"
seed_item "$HOME/.antigravity-ide"        "${DEV_HOME}/.antigravity-ide"        "Extensions (~/.antigravity-ide)"
```

### Planned Spec Tree (AntigravityAuthSeeding.feat -- 18 specs, never written)

What gets **copied**:
- `GeminiDirCopied.spec` -- `~/.gemini` (auth tokens)
- `AntigravityIdeConfigCopied.spec` -- `~/.config/Antigravity IDE` (IDE settings)
- `AntigravityIdeExtensionsCopied.spec` -- `~/.antigravity-ide` (extensions)

What gets **excluded** (15 exclusion filters):
- `BrainDirExcluded.spec` -- `brain/` (conversation artifacts)
- `ConversationsDirExcluded.spec` -- `conversations/`
- `CrashesDirExcluded.spec` -- `crashes/`
- `BrowserRecordingsDirExcluded.spec` -- browser recordings
- `AntigravityBrowserProfileExcluded.spec` -- browser profile
- `ScratchDirExcluded.spec` -- `scratch/`
- `CacheDirExcluded.spec` -- `cache/`
- `CodeCacheDirExcluded.spec` -- code cache
- `CachedDataDirExcluded.spec` -- cached data
- `WorkspaceStorageDirExcluded.spec` -- workspace storage
- `HistoryDirExcluded.spec` -- history
- `BackupsDirExcluded.spec` -- backups
- `LogsDirExcluded.spec` -- logs
- `BinFilesExcluded.spec` -- `*.bin` files
- `AgyMissingSourceDirEmitsWarnContinues.spec` -- graceful degradation

### Design Rationale

Auth seeding enables running AGY inside the sandbox without re-authenticating.
The exclusion filters prevent copying transient/large data (brain state, cached
binaries, conversation logs) that would bloat the virtual root and potentially
leak sensitive conversation data between environments.

---

## 7. Vuniverse Environment Configuration (recovered from deleted `0055-vuniverse-env.md`)

### Env Var Provenance

Every env var in the vuniverse has exactly one source:

| Variable | Source | Value |
|----------|--------|-------|
| `HOME` | config | `/home/sandbox-user` |
| `USER` | config | `sandbox-user` |
| `SHELL` | config | `/bin/bash` |
| `LC_ALL` | config | `C.UTF-8` |
| `PATH` | computed | Built from toolchain + lang profile |
| `TERM` | host | Pass through for terminal compat |
| `LANG` | host | Locale |
| `HANADEN_ENV` | host | `dev`/`prod` -- drives lang_choice |
| `HANADEN_CONV_ID` | host | AI_CONV_ID from agent |
| `HANADEN_REGEN_N` | computed | Incremented on each self-regen execve |
| `HANADEN_BOOT_TS` | computed | Timestamp of initial boot (survives regen) |
| `HANADEN_PID` | computed | `$$` |
| `HANADEN_LANG` | computed | Active lang from lang profile |

Three provenance types:
- **host** -- passed through from host env at backend launch (allowlist)
- **config** -- defined in config spec, static value
- **computed** -- derived at boot from other config/runtime values

---

## 8. Vuniverse Filesystem Layout (recovered from deleted `0060-vuniverse-fs.md`)

### EPHEMERAL_HOME

```
Formula:  ${TMPDIR:-/tmp}/hanaden-ai/<AI_CONV_ID>/pid-<PID>
Example:  /tmp/hanaden-ai/cc61ee22-941d-4c6e-8a32-0db5536093cd/pid-12345
```

Parts:
- `base` = `${TMPDIR:-/tmp}/hanaden-ai` (literal prefix)
- `conv_id` = `AI_CONV_ID` (from env, set by IDE/launcher)
- `pid` = `getpid()` (stable across execve self-regen)

### Vuniverse Backend Profiles (recovered from deleted `0058-vuniverse-backend*.md`)

The vuniverse supports multiple isolation backends via profile system:

| Backend | Status | Notes |
|---------|--------|-------|
| `bwrap-enhanced` | **Active** | Primary implementation |
| `bwrap` (raw bubblewrap) | Stub | Minimal, no enhanced features |
| `docker` | Stub | Container-based |
| `podman` | Stub | Rootless container |
| `firejail` | Stub | Seccomp-based |
| `gvisor` | Stub | User-space kernel |
| `nspawn` | Stub | systemd-nspawn |

Each backend translates the generic mount spec into its own flag syntax.

---

## 9. Security Tier Model -- T0 through T6

| Tier | Shield State | `ctrl` flags (OR within tier) | Host FS exposure |
|:----:|:---:|---|---|
| **T0** | Full | Core VFS + home RW (under root-dir) | Home dir only (persisted, by design) |
| **T1** | UP | `--enable-wayland` `--enable-audio` `--enable-a11y` | Zero host FS |
| **T2** | UP | `--enable-gnome` `--enable-kde` | Zero host FS |
| **T3** | UP | `--enable-mise-ro` `--enable-local-bin-ro` | Bounded host FS **READ** |
| **T4** | UP | `--enable-mise-rw` `--enable-local-bin-rw` `--enable-opt-rw` | Bounded host FS **WRITE** (persists) |
| **T5** | PIERCED | `--enable-dbus` | Unbounded host FS via portals |
| **T6** | DOWN | No sandbox (no `ctrl`) | All host resources |

**`--share-net` is orthogonal -- NOT a tier.**

### Capability Matrix

| Capability / Flag | T0 | T1 | T2 | T3 | T4 | T5 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| `--enable-wayland` | - | Y | Y | Y | Y | Y |
| `--enable-audio` | - | Y | Y | Y | Y | Y |
| `--enable-a11y` | - | Y | Y | Y | Y | Y |
| `--enable-gnome` | - | - | Y | Y | Y | Y |
| `--enable-kde` | - | - | Y | Y | Y | Y |
| `--enable-mise-ro` / `--enable-local-bin-ro` | - | - | - | Y | Y | Y |
| `--enable-mise-rw` / `--enable-local-bin-rw` | - | - | - | - | Y | Y |
| `--enable-opt-rw` | - | - | - | - | Y | Y |
| `--enable-dbus` | - | - | - | - | - | Y |
| Host D-Bus session bus visible | - | - | - | - | - | Y |
| Portal file picker -> host FS | - | - | - | - | - | Y |
| Host keyring accessible | - | - | - | - | - | Y |
| **Host FS escape vector** | - | - | - | - | - | **YES** |

---

## 10. Planned SDLC Hierarchy (79 nodes -- never written)

```
JailProvisioner2026.strat                       (EXISTS -- never committed)
+-- ImplementationLanguageSelection.decis       (EXISTS -- never committed)
+-- ManualVrootConstruction.driv                (NOT WRITTEN)
+-- VirtualHomeLayout.arch                      (NOT WRITTEN)
+-- CliApi.feat                                 (NOT WRITTEN -- 12 specs)
|   +-- NoArgExitsZero.spec
|   +-- NoArgPrintsAttribution.spec
|   +-- NoArgPrintsLicense.spec
|   +-- NoArgPrintsImmutablePrinciple.spec
|   +-- NoArgPrintsUsageSection.spec
|   +-- NoArgPrintsExamplesSection.spec
|   +-- HelpFlagMatchesNoArg.spec
|   +-- HelpBannerDefault.spec
|   +-- PosixErrorFormat.spec
|   +-- UnknownFlagExitsTwo.spec
|   +-- MissingRequiredArgExitsTwo.spec
|   +-- UsageHintOnError.spec
+-- ContextDerivation.feat                      (NOT WRITTEN -- 7 specs)
|   +-- ProjectNameFromGitBasename.spec
|   +-- ProjectNameFromEnvVar.spec
|   +-- ProjectNameFromFlag.spec
|   +-- VirtualUserDefaultsToDeveloper.spec
|   +-- VirtualUserOverriddenByFlag.spec
|   +-- TargetBaseDirConstructed.spec
|   +-- TargetBaseDirOverriddenByFlag.spec
+-- VrootSkeletonProvisioning.feat              (NOT WRITTEN -- 8 specs)
|   +-- ConfigDirCreated.spec
|   +-- LocalShareDirCreated.spec
|   +-- LocalBinDirCreated.spec
|   +-- CacheDirCreated.spec
|   +-- TmpDirCreated.spec
|   +-- RunDirCreated.spec
|   +-- SshDirCreatedMode700.spec
|   +-- GnupgDirCreatedMode700.spec
+-- IdempotencyBehavior.feat                    (NOT WRITTEN -- 4 specs)
|   +-- ExistingDirNotOverwritten.spec
|   +-- ExistingDirEmitsInfoWarn.spec
|   +-- ExistingFileNotOverwritten.spec
|   +-- ExistingFileEmitsInfoWarn.spec
+-- GenericSeeding.feat                         (NOT WRITTEN -- 4 specs)
|   +-- SingleFileSeeded.spec
|   +-- DirectoryRecursivelySeeded.spec
|   +-- MissingSourceFileEmitsWarnContinues.spec
|   +-- MissingSourceDirEmitsWarnContinues.spec
+-- AntigravityAuthSeeding.feat                 (NOT WRITTEN -- 18 specs)
|   +-- (see Section 6 above for full list)
+-- LibrarySourcingMode.feat                    (NOT WRITTEN -- 5 specs)
|   +-- SourcedDetectedViaBashSource.spec
|   +-- ProvisionVrootFunctionExported.spec
|   +-- SeedAntigravityLoginFunctionExported.spec
|   +-- NoExecutionOnSource.spec
|   +-- NoHelpPrintedOnSource.spec
+-- ObservabilityAndLogging.feat                (NOT WRITTEN -- 6 specs)
|   +-- InfoPrefixOnInfoMessages.spec
|   +-- WarnPrefixOnWarnMessages.spec
|   +-- ErrorPrefixOnErrorMessages.spec
|   +-- AllLogOutputToStderr.spec
|   +-- ExitsZeroOnSuccess.spec
|   +-- ExitsNonZeroOnFatalError.spec
+-- ScriptIntegrity.feat                        (NOT WRITTEN -- 3 specs)
    +-- ZeroNonAsciiBytes.spec
    +-- BootMirrorByteIdentical.spec
    +-- ScriptIsExecutable.spec
```

### Summary Counts

| Node Type | Planned | Written | Remaining |
|-----------|--------:|--------:|----------:|
| STRAT     | 1       | 1       | 0         |
| DECIS     | 1       | 1       | 0         |
| DRIV      | 1       | 0       | 1         |
| ARCH      | 1       | 0       | 1         |
| FEAT      | 9       | 0       | 9         |
| SPEC      | 67      | 0       | 67        |
| **Total** | **80**  | **2**   | **78**    |

---

## 11. Test Suites Inventory (721 LOC -- never committed)

| Test File | Feature Coverage | LOC |
|-----------|-----------------|----:|
| `test_cli_interface.sh` | CliApi (7 original specs) | 76 |
| `test_context_derivation.sh` | ContextDerivation | 82 |
| `test_vroot_skeleton.sh` | VrootSkeletonProvisioning | 69 |
| `test_idempotency.sh` | IdempotencyBehavior | 67 |
| `test_generic_seeding.sh` | GenericSeeding | 68 |
| `test_antigravity_auth_seeding.sh` | AntigravityAuthSeeding | 146 |
| `test_library_sourcing.sh` | LibrarySourcingMode | 62 |
| `test_observability.sh` | ObservabilityAndLogging | 73 |
| `test_script_integrity.sh` | ScriptIntegrity | 78 |

These test suites existed on the remote mount at
`PROJECT_HOME/src/test/hanaden-vuniverse-provisioner/` but were never committed
to git. They may still exist on the remote filesystem if the mount is accessible.

---

## 12. Language Decision (recovered from `ImplementationLanguageSelection.decis`)

**Current:** Bash v0.x (259 LOC for provisioner, ~650 LOC for bwrap-enhanced.sh)

**Migration criteria** (any one triggers):
- Code exceeds 500 LOC
- Needs config file parsing (YAML/JSON/TOML)
- Needs network operations
- Needs parallelism
- Needs cross-platform support

**Target language:** Originally Go (cobra) was considered. Given current project
direction (Rust kanban engine, Rust SDLC engine), **Rust** is the natural target.

**Design constraints:**
- Pure ASCII, zero deps beyond coreutils (Bash phase)
- CLI-first, API-driven (no REST API -- "API" = library sourcing mode in Bash, crate API in Rust)
- Idempotent (re-running never overwrites existing files/dirs)
- Zero coupling between modules at the filesystem level
- POSIX-compliant error handling

---

## 13. Key Design Decisions

| # | Decision | Status |
|---|----------|--------|
| 1 | Root spec format: JSON Schema via `provision schema` | Active |
| 2 | No GC -- delete manually with `rm -rf ${ROOT_DIR}` | Active |
| 3 | No `--base-etc` preset -- use host `/etc` RO | Active |
| 4 | Backward compat shim -- **Ignored**, not a priority | Active |
| 5 | `provision create` errors if `${ROOT_DIR}` exists | Active |
| 6 | Tests -- deferred, test suite redesign needed | Active |
| 7 | Sandbox sentinel -- **Dropped** (over-engineering for local dev) | Dropped |
| 8 | Application name: **vuniverse** (not provisioner, not bwrap-enhanced) | Active |
| 9 | Module architecture: `provision` + `ctrl` subcommands | Active |
| 10 | Antigravity auth seeding: 3 paths, 15 exclusion filters | Active |

---

## 14. Buildout Phases (from never-committed buildout plan)

The buildout plan defined 7 phases:

| Phase | Description | Status |
|-------|-------------|--------|
| P-A | Generate UUIDs for all 78 SDLC files | Not started |
| P-B | Create driver (ManualVrootConstruction.driv) + architecture (VirtualHomeLayout.arch) | Not started |
| P-C | Create 9 feat files | Not started |
| P-D | Create 67 spec files | Not started |
| P-E | Verify hierarchy integrity | Not started |
| P-F | Update vuniverse script for POSIX CLI compliance | Not started |
| P-G | Run all test suites | Not started |

---

## 15. Relationship to Other Systems

### SDLC Engine (one-way dependency)

Vuniverse reads SDLC specs for spec-code traceability. The SDLC engine does
NOT know about vuniverse. Same pattern as the Kanban engine.

### Kanban Engine (workflow tracking)

Vuniverse work items live in the workstream-kanban system once promoted from
brainstorming to actionable work. Currently still in brainstorm stage.

### bwrap-enhanced.sh (will be absorbed)

The current `bwrap-enhanced.sh` becomes the `ctrl` module implementation.
No breaking changes -- it's a rename + module wrapping.

---

<!-- END OF BRAINSTORM -->
<!-- Status: comprehensive recovery document, not reviewed, not committed, not specced -->
<!-- Sources: VirtualRootProvisionerArch.brainstorm, conversation fb847726 rediscovery -->
<!--          report, git e0b1dba~1 deleted specs, user shell history -->
