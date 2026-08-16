
## Vuniverse Backend Selection

The vuniverse runs inside a backend — the isolation/containerization layer.
Each backend has a profile file (`config/0058-vuniverse-backend-*.md`).

### Backend Selection

```toml
[backend.dev]
backends_allowed = ["bwrap-enhanced", "bwrap", "docker", "podman", "firejail", "gvisor", "nspawn"]
backend_choice   = "locked"    # locked | ai-choice | first-available
backend_locked   = "bwrap-enhanced"

[backend.prod]
backends_allowed = ["bwrap-enhanced", "docker", "podman"]
backend_choice   = "locked"
backend_locked   = "bwrap-enhanced"
```

**Selection algorithms:**
- `locked` — use `backend_locked` value. FATAL if not available.
- `ai-choice` — AI agent picks from `backends_allowed`. Must be available.
- `first-available` — iterate `backends_allowed` in order, use first where binary exists and is executable.

**Override priority (highest wins):**
1. CLI flag: `--backend=docker`
2. Env var: `HANADEN_BACKEND=docker`
3. Config: `backend_locked` (this file)
4. Fallback: `first-available` from `backends_allowed`

### Profile Contract

Each per-backend profile (`config/0058-vuniverse-backend-*.md`) MUST define:

```toml
[profile]
name              = "<backend name>"
binary            = "<path or command>"
binary_check_cmd  = "<command to verify backend is available>"

[flags]
clear_env         = "<flag to clear environment>"
host_root         = "<flag to mount host root>"
home_parent       = "<flag to set home parent>"
bind_ro           = "<flag template for read-only bind mount>"
bind_rw           = "<flag template for read-write bind mount>"
mkdir             = "<flag template to create directory>"
set_env           = "<flag template to set env var>"
entry_separator   = "<separator before entry command>"

[capabilities]
signal_forwarding = true|false     # does the backend forward signals to child?
pid_namespace     = true|false     # does the backend create a PID namespace?
network_isolation = true|false     # does the backend isolate network?
tmpfs_on_tmp      = true|false     # does the backend mount tmpfs on /tmp?
```

### Dependencies

```
config/0058-vuniverse-backend.md       -> THIS FILE (general + contract)
config/0058-vuniverse-backend-*.md     -> per-backend profiles
config/0060-vuniverse-fs.md            -> provides: mount list consumed by backend
config/0055-vuniverse-env.md           -> provides: env vars set via backend flags
```
