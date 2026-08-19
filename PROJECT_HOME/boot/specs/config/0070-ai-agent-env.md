<!-- (c) 2026-* Frederick Bloom -- 0070-ai-agent-env.md -- Hanaden AI -->

## AI Agent Session Environment

Host-side configuration for AI agents (Antigravity, Claude CLI, Ollama, etc.)
when they start a conversation session. This is NOT the vuniverse — this is the
HOST environment that the agent runs in before launching the vuniverse.

### 1. Toolchain (host-side)

```toml
[toolchain]
# Tools available on the HOST, resolved at session start.
# Used by the AI agent during Phase 1 (daemon generation) and for
# AGENTS.md-mandated command prefixing.

[toolchain.mise]
activation = 'eval "$(~/.local/bin/mise activate bash)"'
bin        = "~/.local/bin/mise"
purpose    = "Tool/runtime version management"

[toolchain.rtk]
resolution = "$(mise which rtk)"
prefix_rule = "ALL AI-issued shell commands MUST be prefixed with rtk"
purpose     = "Output compression for token efficiency"

[toolchain.uv]
resolution = "$(mise which uv)"
purpose    = "Python package management (if needed on host)"
```

### 2. Session Startup

```toml
[session]
# Steps the AI agent MUST perform at conversation init:
steps = [
    "eval \"$(~/.local/bin/mise activate bash)\"",     # activate mise shims
    "read PROJECT_HOME/boot/specs/ in order: config/ -> cmdstream/ -> design/",
]

# RTK prefix mandate:
# User conversational shorthand (e.g., "ls", "git log") MUST be silently
# translated to "rtk ls", "rtk git log", etc.
```

### 3. Sidecar Spinup

```toml
[sidecar]
# When the AI agent launches in HEADLESS mode or the daemon needs
# an ai-exec-runner subprocess, the sidecar is resolved here.
# This is the HOST-side equivalent of config/0600-lifecycle-sidecar.md
# (which covers sidecar from the daemon's perspective inside the vuniverse).

# Sidecar discovery is dynamic — see design/0100 Step 5b.
# The host toolchain (mise, rtk) is available to the sidecar.
```

### Ownership

This file owns ONLY: **host-side toolchain activation, session startup, sidecar resolution.**

It does NOT own:
- Vuniverse internal env vars (`config/0055-vuniverse-env.md`)
- Vuniverse filesystem (`config/0060-vuniverse-fs.md`)
- Backend selection (`config/0058-vuniverse-backend.md`)
- Lang profile (`config/0045-lang-profile.md`)
