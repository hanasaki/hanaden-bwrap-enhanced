# Virtual Root + Provisioner Architecture — Brainstorming
<!-- brainstorming-ideas-only — NOT a spec, NOT a commitment -->
<!-- Created:  2026-08-25T23:48:18Z -->
<!-- Revised:  2026-08-26T00:09:07Z -->
<!-- ID: 20260825-234818-159890-7bd1-86c0-6cfd6234e1f1 -->

---

## Origin

This document captures ideas beginning from the "Ruthless, kind, full critique" discussion
in the security tier model design session. These are brainstorming notes only — not
approved specs, not committed architecture. Use to seed future planning.

---

## 1. Corrections to Initial Critique

The original critique incorrectly attributed "virtual-root RW" to the user's design.
That was a fabrication error in the analysis. The user's actual intent, confirmed, was:

- **Virtual root** (`--root-dir`) → **RO** at runtime (`--remount-ro /` applied by Controller)
- **`/tmp`, `/dev/shm`** → fresh **tmpfs** (RW, ephemeral, kernel-managed)
- **`/run/user/UID`** → fresh **tmpfs** (RW, ephemeral, kernel-managed)
- **Home dir** (`/home/${VIRTUAL_USER}`) → **RW**, persisted to host under
  `${ROOT_DIR}/home/${VIRTUAL_USER}/`

The virtual root root itself is immutable at runtime. Only the home dir and kernel tmpfs
mounts are writable. This is NOT a security regression — it is the correct design.

---

## 2. The Corrected Design — Definitive Statement

### The Virtual Root Is an Overlay, Not a Full OS Copy

The virtual root dir contains ONLY the synthetic/override layer:

```
${ROOT_DIR}/              ← --root-dir on host; "/" inside sandbox
  etc/                    ← synthetic minimum subset (fake passwd, group, resolv.conf,
  |                          ld.so.cache-bind, ssl/certs-bind, bash profile stub)
  home/
    ${VIRTUAL_USER}/      ← RW, persisted to host; "/home/${VIRTUAL_USER}" inside sandbox
  tmp/                    ← empty dir; replaced by fresh tmpfs at runtime
  dev/                    ← empty dir; populated by bwrap device setup
  proc/                   ← empty dir; populated by bwrap --proc
  run/                    ← empty dir; replaced by fresh tmpfs at runtime
  var/                    ← empty dir (host /var bound RO on top at runtime)
  opt/                    ← empty dir (host /opt bound RO on top at runtime)
```

At runtime the Controller (bwrap) additionally binds from host, all **RO**:
- `/usr` → host `/usr`
- `/lib`, `/lib64`, `/bin`, `/sbin` → host equivalents (or symlinks)
- `/var` → host `/var`
- `/opt` → host `/opt` (default RO; override with `--enable-opt-rw`)

No full OS copy. No package manager bootstrap. No container image required.
Virtual root dir is lightweight — kilobytes, not gigabytes.

### Home Dir — Persistence Model

The home dir lives at `${ROOT_DIR}/home/${VIRTUAL_USER}/` on the host.
Inside the sandbox it is mounted at `/home/${VIRTUAL_USER}` as **RW**.

This is **NOT ephemeral** by default. Data written to `~` inside the sandbox
persists across runs, just like a real user's home directory.

"Ephemeral" is a CHOICE: the operator deletes `${ROOT_DIR}/` after use.
By default the provisioned environment accumulates state across runs — this is
the intended behavior for developer workspaces.

The current flag `--host-real-home-parent` is confusing and should be replaced:

| Old | New | Notes |
|---|---|---|
| `--host-real-home-parent PATH` | `--home-dir PATH` | PATH is absolute inside sandbox; default `/home/${VIRTUAL_USER}` |

On the host, the home resolves to: `${ROOT_DIR}${HOME_DIR}` (i.e. `${ROOT_DIR}/home/${VIRTUAL_USER}`).
The Provisioner creates this directory during `provision create`. There is no separate
home-parent concept — the home is always a subdirectory of `--root-dir`.

**Self-contained blast zone:** deleting `${ROOT_DIR}/` removes the entire
environment (root + home) atomically. No scattered state across multiple host paths.

---

## 3. Revised CLI Specification (brainstorm — proposed, not final)

### Top-Level Structure

```
bwrap-enhanced <module> [module-options] [-- CMD [ARGS...]]

Modules:
  provision    Manage virtual root environments (Provisioner / Control Plane)
  ctrl         Execute a process inside a sandbox   (Controller / Data Plane)
```

### Module: `provision`

Full mutable write access to `${ROOT_DIR}`. Runs externally, never inside a sandbox.
Safety: refuses to execute if `BWRAP_SANDBOX=1` is set (or equivalent namespace check).

```
bwrap-enhanced provision <subcommand> [options]

Subcommands:
  create      Create a new virtual root environment (errors if already exists; prints full path)
  modify      Add or remove components from an existing root
  describe    Show current state and contents of a root
  list        List all roots under a given parent directory
  snapshot    Save a point-in-time copy of a root before modification
  diff        Show what changed between two snapshots
  schema      Print the JSON Schema for the virtual root spec to stdout
  gc          [DEFERRED — no GC for now; delete manually with rm -rf ${ROOT_DIR}]

create options:
  --root-dir PATH            Required. Must not already exist (errors + shows full path if it does).
  --virtual-user NAME        Virtual username [default: sandbox-user]
  --home-dir PATH            Home path inside sandbox [default: /home/${VIRTUAL_USER}]
  [/etc: bound from host /etc RO — no preset system, existing ro-bind-data behavior retained]

modify options:
  --root-dir PATH            Required.
  --add COMPONENT            Component to add (see component list below)
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

schema options:
  [none — prints JSON Schema for the virtual root spec to stdout]
  Usage: bwrap-enhanced provision schema > vroot.schema.json

gc: [DEFERRED — no implementation planned yet; delete manually with rm -rf ${ROOT_DIR}]
```

### Module: `ctrl`

Read-only consumer of `${ROOT_DIR}`. Applies bwrap namespace isolation and
executes CMD inside the sandbox. Replaces the current bare `bwrap-enhanced.sh`
invocation and the old implied "run" subcommand.

```
bwrap-enhanced ctrl [options] -- CMD [ARGS...]

Core options:
  --root-dir PATH            Virtual root dir [default: ~/virtual-roots/default]
  --virtual-user NAME        Virtual username inside sandbox [default: sandbox-user]
  --home-dir PATH            Home inside sandbox [default: /home/${VIRTUAL_USER}]

Tier 1 — RO socket passthrough (zero host FS exposure):
  --enable-wayland           Bind wayland-0 socket RO
  --enable-audio             Bind pipewire-0 and/or pulse socket RO
  --enable-a11y              Bind AT-SPI bus socket RO

Tier 2 — RW socket passthrough (bidirectional IPC, no host FS files):
  --enable-gnome             Bind dconf, keyring, gvfs, gcr sockets RW
  --enable-kde               Bind kwallet5, ksmserver, drkonqi sockets RW

Tier 3 — Bounded host FS READ (reads specific host dirs; zero host FS write):
  --enable-mise-ro           Bind ~/.local/share/mise and ~/.config/mise RO
  --enable-local-bin-ro      Bind ~/.local/bin RO

Tier 4 — Bounded host FS WRITE (writes persist to host after exit):
  --enable-mise-rw           Bind ~/.local/share/mise and ~/.config/mise RW
  --enable-local-bin-rw      Bind ~/.local/bin RW
  --enable-opt-rw            Bind /opt RW [default: /opt bound RO from host]

Tier 5 — Portal bridge (SHIELDS PIERCED — unbounded host FS via D-Bus portals):
  --enable-dbus              Enable D-Bus session bus

Orthogonal options (independent of tier; combinable at any tier):
  --share-net                Share host network namespace [default: --unshare-net]
```

### Backward Compatibility

The old invocation style `bwrap-enhanced.sh [options] -- CMD` continues to work
via a shim/alias that maps to `bwrap-enhanced ctrl`. Flag renames:

| Old flag | New flag | Notes |
|---|---|---|
| `--host-real-root PATH` | `--root-dir PATH` | Same semantics |
| `--host-real-home-parent PATH` | `--home-dir PATH` | Semantics change: now absolute path INSIDE sandbox, not host parent dir |
| `--virtual-user-name NAME` | `--virtual-user NAME` | Shorter |
| *(bare script)* | `ctrl` subcommand | `bwrap-enhanced ctrl ...` |

---

## 4. Tier Model — Final Corrected Version

| Tier | Shield State | `ctrl` flags (OR within tier) | Host FS exposure |
|:----:|:---:|---|---|
| **T0** | ✅ Full | Core VFS · home RW (under root-dir) | Home dir only (persisted, by design) |
| **T1** | 🛡️ UP | `--enable-wayland` `--enable-audio` `--enable-a11y` | Zero host FS |
| **T2** | 🛡️ UP | `--enable-gnome` `--enable-kde` | Zero host FS |
| **T3** | 🛡️ UP | `--enable-mise-ro` `--enable-local-bin-ro` | Bounded host FS **READ** |
| **T4** | 🟠 UP | `--enable-mise-rw` `--enable-local-bin-rw` `--enable-opt-rw` | Bounded host FS **WRITE** (persists) |
| **T5** | 🕳️ PIERCED | `--enable-dbus` | Unbounded host FS via portals |
| **T6** | 💀 DOWN | No sandbox (no `ctrl`) | All host resources |

**Tier separation rationale:**
- T1 vs T2: RO socket binds (one-directional IPC) vs RW socket binds (bidirectional,
  touches credential daemons). Different directionality, different exposure.
- T2 vs T3: Socket IPC (no host FS content readable) vs host FS directory bind
  (real host files readable, extractable). Axis crossing.
- T3 vs T4: Read-only vs read-write host FS. Write persists after sandbox exit.
- T4 vs T5: Bounded write (known paths) vs unbounded FS via portal bridge (arbitrary paths).
- `--enable-opt-rw` at T4: /opt is a system-level path (higher blast radius than
  mise-rw which is user-level), but still bounded (no portal escape). Fits T4.

**`--share-net` is orthogonal — NOT a tier:**
- Default: network isolated (`--unshare-net`). Compatible with ALL T1 and T2 flags —
  wayland, audio, a11y, gnome, kde all use Unix sockets; isolated network does NOT break them.
- gvfs network mounts (SMB/FTP) fail without `--share-net` — correct behavior
  (prevents gvfs from being a covert exfil channel even at T2).
- `--share-net` is a risk multiplier: adds network exfil/ingress channel at any tier.
- T5 + `--share-net` = portals + exfil channel = maximum risk.

**Capability Matrix:**

| Capability / Flag | T0 | T1 | T2 | T3 | T4 | T5 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| `--enable-wayland` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `--enable-audio` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `--enable-a11y` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `--enable-gnome` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| `--enable-kde` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| `--enable-mise-ro` / `--enable-local-bin-ro` | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| `--enable-mise-rw` / `--enable-local-bin-rw` | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `--enable-opt-rw` | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `--enable-dbus` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Host D-Bus session bus visible | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Portal file picker → host FS | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Host keyring accessible | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Host FS escape vector** | ❌ | ❌ | ❌ | ❌ | ❌ | **⚠️ YES** |
| `--share-net` (opt-in, any tier) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

Note: T1 split from T2 (RO vs RW socket binds) — gnome/kde now T2, not T1.

---

## 5. The Overlay Model — Confirmed

The virtual root dir is the synthetic override layer. The Controller binds host
runtime on top at execution time. No OS copy needed.

```
At provision time (Provisioner):
  ${ROOT_DIR}/etc/         ← synthetic: fake passwd/group, stub resolv.conf,
  ${ROOT_DIR}/home/${V}/   ← created empty; RW home lives here
  ${ROOT_DIR}/tmp/         ← empty placeholder
  ${ROOT_DIR}/run/         ← empty placeholder
  ${ROOT_DIR}/var/         ← empty placeholder
  ${ROOT_DIR}/opt/         ← empty placeholder

At runtime (Controller — bwrap args):
  / bound from ${ROOT_DIR} (RO, --remount-ro /)
  /usr      bound from host /usr      (RO)
  /lib      bound from host /lib      (RO)
  /bin      bound from host /bin      (RO)
  /var      bound from host /var      (RO)
  /opt      bound from host /opt      (RO) [or RW with --enable-opt-rw]
  /etc/ld.so.cache bound from host    (RO, needed for dynamic linker)
  /etc/ssl  bound from host           (RO, needed for TLS)
  /tmp      → fresh tmpfs             (RW, ephemeral)
  /dev/shm  → fresh tmpfs             (RW, ephemeral)
  /run/user/${UID} → fresh tmpfs      (RW, ephemeral)
  /home/${V} bound from ${ROOT_DIR}/home/${V} (RW, persisted)
```

The host OS provides the runtime. The virtual root provides the identity, home,
and synthetic system configuration. These are orthogonal responsibilities.

---

## 6. Provisioner / Controller — Two-Plane Architecture

```
┌─────────────────────────────────────────────┐
│  PROVISIONER (Control Plane)                │
│  bwrap-enhanced provision <subcommand>      │
│                                             │
│  • Runs on host, never inside sandbox       │
│  • Full RW access to ${ROOT_DIR}            │
│  • Creates, modifies, inspects, removes     │
│    virtual root environments                │
│  • Refuses if BWRAP_SANDBOX=1 is set        │
└─────────────────────────────────────────────┘
            │ creates / manages
            ▼
┌─────────────────────────────────────────────┐
│  ${ROOT_DIR}/  (Virtual Root on host)       │
│  etc/ home/${V}/ tmp/ run/ var/ opt/ ...    │
└─────────────────────────────────────────────┘
            │ used read-only (except home)
            ▼
┌─────────────────────────────────────────────┐
│  CONTROLLER (Data Plane)                    │
│  bwrap-enhanced ctrl [options] -- CMD       │
│                                             │
│  • Runs on host, exec's into sandbox        │
│  • Reads ${ROOT_DIR} (RO at runtime)        │
│  • Applies bwrap namespace isolation        │
│  • Adds tier-specific binds per flags       │
│  • Sandboxed process has no access to       │
│    Provisioner or host outside binds        │
└─────────────────────────────────────────────┘
```

Aligned with CONSTITUTION.md Immutable Principle:
- External Construction → Provisioner designs and provisions the jail before execution
- External Enforcement → bwrap kernel namespaces enforce from outside
- Zero Self-Policing → sandboxed process cannot modify its own confinement

---

## 7. Resolved Decisions (from Q&A)

| # | Question | Decision |
|---|---|---|
| 1 | Root spec format | JSON Schema. `provision schema` emits it to stdout. Spec files (YAML/JSON) validate against it. Self-documenting, no external deps. |
| 2 | GC | **No GC.** Deferred indefinitely. Delete manually: `rm -rf ${ROOT_DIR}`. No daemon, no reference counting. |
| 3 | `--base-etc` preset | **Dropped.** Use host `/etc` RO (existing `--ro-bind-data` overrides for passwd/group retained). No preset system. |
| 4 | Backward compat shim | **Ignored.** Not a priority. |
| 5 | `provision create` error | Error if `${ROOT_DIR}` already exists. Print full resolved path on error and on success. |
| 6 | Tests | **Deferred.** Test suite to be redesigned separately. |
| 7 | Sandbox sentinel | **Dropped.** A process that escapes bwrap already runs as the developer on the host with full access to everything (SSH keys, home dir, etc). Blocking Provisioner access adds no meaningful protection. Over-engineering for local dev. |


<!-- END OF BRAINSTORM -->
<!-- Status: ideas only, not reviewed, not committed, not specced -->
<!-- Revised: 2026-08-26T00:09:07Z -->
