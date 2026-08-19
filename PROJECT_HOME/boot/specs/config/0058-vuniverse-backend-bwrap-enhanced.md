<!-- (c) 2026-* Frederick Bloom -- 0058-vuniverse-backend-bwrap-enhanced.md -- Hanaden AI -->

## Vuniverse Backend Profile: bwrap-enhanced

```toml
[profile]
name              = "bwrap-enhanced"
binary            = "PROJECT_HOME/boot/bwrap-enhanced.sh"
binary_check_cmd  = "test -x PROJECT_HOME/boot/bwrap-enhanced.sh"
description       = "Enhanced bubblewrap wrapper with tmpfs on /homes, fake passwd/group, profile.d suppression"

[flags]
clear_env         = "--clear-env"
host_root         = "--host-real-root {src}"
home_parent       = "--host-real-home-parent {src}"
bind_ro           = "--ro-bind {src} {dst}"
bind_rw           = "--bind {src} {dst}"
mkdir             = "--dir {path}"
set_env           = "--setenv {key} {value}"
entry_separator   = "--"

[capabilities]
signal_forwarding = true       # bwrap execs daemon as PID 1 — signals go direct
pid_namespace     = false      # no --unshare-pid by default
network_isolation = false      # no --unshare-net by default
tmpfs_on_tmp      = true       # bwrap-enhanced.sh mounts --tmpfs /tmp unconditionally
tmpfs_on_homes    = true       # bwrap-enhanced.sh mounts --tmpfs /homes unconditionally
```

### Constraints

```toml
[constraints]
# /tmp is tmpfs — host /tmp paths invisible inside vuniverse
# /homes is tmpfs — PROJECT_HOME invisible inside vuniverse
# EPHEMERAL_HOME lives under /tmp on host — invisible inside vuniverse
# Daemon source MUST be at EPHEMERAL_HOME/home/sandbox-user/<filename>
#   which maps to /home/sandbox-user/<filename> inside vuniverse via --host-real-home-parent

# Tool binaries MUST be mounted at their absolute host paths using --ro-bind
# MUST-NOT use mise shims (symlinks to /homes/... which is hidden by tmpfs)
# MUST create parent dirs with --dir before --ro-bind for files under /homes tmpfs
```

### Invocation Template

```bash
# Assembled by boot/vuniverse.sh from launch.manifest
bwrap-enhanced.sh --clear-env \
    --host-real-root        /                           \
    --host-real-home-parent EPHEMERAL_HOME/home          \
    --dir     MISE_BIN_DIR                               \
    --ro-bind MISE_BIN  MISE_BIN                         \
    --dir     RTK_BIN_DIR                                \
    --ro-bind RTK_BIN   RTK_BIN                          \
    --dir     UV_BIN_DIR                                 \
    --ro-bind UV_BIN    UV_BIN                           \
    --dir     MISE_DATA_DIR/installs                     \
    --ro-bind MISE_DATA_DIR/installs MISE_DATA_DIR/installs \
    --dir     MISE_DATA_DIR/downloads                    \
    --ro-bind MISE_DATA_DIR/downloads MISE_DATA_DIR/downloads \
    -- <entry_cmd per lang profile>
```

### Anti-Regression

```toml
[anti_regression]
mandates = [
    "--host-real-root MUST be / (host root). MUST-NOT use EPHEMERAL_HOME as host-real-root.",
    "EPHEMERAL_HOME is used ONLY for --host-real-home-parent.",
    "Tool binaries MUST be mounted via --ro-bind at their absolute host paths.",
    "MUST-NOT use mise shims inside vuniverse (shims are symlinks to /homes/... hidden by tmpfs).",
    "Pre-seed for bwrap MUST be mkdir -p EPHEMERAL_HOME/home/sandbox-user.",
    "MUST-NOT pre-seed EPHEMERAL_HOME/homes.",
]
```
