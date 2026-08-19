<!-- (c) 2026-* Frederick Bloom -- 0060-vuniverse-fs.md -- Hanaden AI -->

## Vuniverse Filesystem Layout

The complete filesystem specification for the vuniverse. Absorbs and replaces
`config/0100-paths.md`. Defines EPHEMERAL_HOME, mount points, and interior layout.

### 1. EPHEMERAL_HOME

```toml
[ephemeral_home]
formula  = "${TMPDIR:-/tmp}/hanaden-ai/<AI_CONV_ID>/pid-<PID>"
example  = "/tmp/hanaden-ai/cc61ee22-941d-4c6e-8a32-0db5536093cd/pid-12345"

[ephemeral_home.parts]
base     = "${TMPDIR:-/tmp}/hanaden-ai"       # literal prefix
conv_id  = "AI_CONV_ID"                        # from env (set by IDE/launcher)
pid      = "getpid()"                          # stable across execve self-regen
```

### 2. Pre-Seed (MUST run before backend launch)

```bash
mkdir -p EPHEMERAL_HOME/home/sandbox-user     # sandbox-user writable home dir
```

### 3. Mounts

All bind mounts for the vuniverse. This is the SST — the backend translates
these into its own flag syntax using the backend profile.

```toml
[mounts]
# Each mount: type (host-real-root | host-real-home-parent | ro-bind | rw-bind),
#             src (host path), dst (vuniverse path), parent (dir to create first)

[[mounts.entry]]
type   = "host-real-root"
src    = "/"
note   = "Host root as vuniverse base filesystem"

[[mounts.entry]]
type   = "host-real-home-parent"
src    = "EPHEMERAL_HOME/home"
note   = "Maps to /home/sandbox-user inside vuniverse"

# --- Tool binaries (resolved on HOST before launch) ---

[[mounts.entry]]
type   = "ro-bind"
src    = "MISE_BIN"
dst    = "MISE_BIN"
parent = "MISE_BIN_DIR"
note   = "mise binary at its absolute host path (RO)"

[[mounts.entry]]
type   = "ro-bind"
src    = "RTK_BIN"
dst    = "RTK_BIN"
parent = "RTK_BIN_DIR"
note   = "rtk binary at its absolute host path (RO)"

[[mounts.entry]]
type   = "ro-bind"
src    = "UV_BIN"
dst    = "UV_BIN"
parent = "UV_BIN_DIR"
note   = "uv binary at its absolute host path (RO)"

# --- Mise cache (host cache shared into vuniverse) ---

[[mounts.entry]]
type   = "ro-bind"
src    = "MISE_DATA_DIR/installs"
dst    = "MISE_DATA_DIR/installs"
parent = "MISE_DATA_DIR/installs"
note   = "Mise installed tools cache (RO — vuniverse uses host cache)"

[[mounts.entry]]
type   = "ro-bind"
src    = "MISE_DATA_DIR/downloads"
dst    = "MISE_DATA_DIR/downloads"
parent = "MISE_DATA_DIR/downloads"
note   = "Mise downloads cache (RO — no re-download)"

# --- Dev/Prod overrides ---
# In dev mode: mise cache mounts are ro-bind (read-only — use host cache)
# In prod mode: mise cache mounts may be omitted (prod uses pre-built binaries)
```

### 4. Mount Token Resolution

```toml
[mounts.tokens]
# Resolved on HOST before launch by the AI agent or boot/hanaden-daemon.
MISE_BIN         = "~/.local/bin/mise"                    # or: which mise
MISE_BIN_DIR     = "~/.local/bin"                         # dirname(MISE_BIN)
RTK_BIN          = "$(mise which rtk)"                    # e.g. ~/.local/share/mise/installs/rtk/latest/rtk
RTK_BIN_DIR      = "$(dirname $(mise which rtk))"
UV_BIN           = "$(mise which uv)"                     # e.g. ~/.local/share/mise/installs/uv/latest/bin/uv
UV_BIN_DIR       = "$(dirname $(mise which uv))"
MISE_DATA_DIR    = "${XDG_DATA_HOME:-~/.local/share}/mise"

# These are HOST paths — they become vuniverse paths at the same absolute location
# because bwrap-enhanced uses --host-real-root / (host root is the vuniverse root).
```

### 5. Interior Layout (inside vuniverse)

```
/                           -> host root (via host-real-root)
/home/sandbox-user/         -> writable (EPHEMERAL_HOME/home/sandbox-user)
/home/sandbox-user/<daemon> -> daemon source (per lang profile filename)
/homes/                     -> empty tmpfs (PROJECT_HOME hidden) [bwrap-enhanced]
/homes/.../mise             -> RO bind of mise binary at host path
/homes/.../rtk/latest/rtk   -> RO bind of rtk binary at host path
/homes/.../uv/latest/bin/uv -> RO bind of uv binary at host path
/tmp/                       -> empty tmpfs (host /tmp hidden) [bwrap-enhanced]
PATH                        -> MISE_BIN_DIR:RTK_BIN_DIR:UV_BIN_DIR:/usr/bin:/bin
```

### 6. Toolchain Verification (inside vuniverse at boot)

```toml
[toolchain]
# After backend launches, the daemon MUST verify accessibility of each tool:
binaries = ["mise", "rtk", "uv"]

# For each: access(path, X_OK) at its absolute host path inside the vuniverse.
# Pass: log INFO. Fail: log WARN, continue (best-effort, MUST-NOT fail boot).
# Prepend verified tool dirs to PATH.
```

### 7. Identity Paths

```toml
[paths]
PROJECT_HOME     = "(host absolute path -- visible inside vuniverse via host-real-root)"
CWD              = "PROJECT_HOME"    # daemon working directory at boot
EPHEMERAL_HOME   = "(see formula above)"
```

### Dependencies

```
config/0058-vuniverse-backend.md   -> consumes: mounts (translates to backend flags)
config/0055-vuniverse-env.md       -> consumes: PATH formula
config/0045-lang-profile.md        -> consumes: entry_cmd, filename for daemon source
```
