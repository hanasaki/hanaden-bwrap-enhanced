
# 12. Service Controller Design

The daemon service controller: `boot/hanaden-daemon`

## Identity

```
hanaden-daemon 0.0.1
Copyright (c) 2026 Hanaden - Frederick Bloom
```

```bash
#!/bin/bash
# ============================================================================
# hanaden-daemon -- HANADEN-AI Daemon Service Controller
# ============================================================================
#
# Copyright (c) 2026 Hanaden - Frederick Bloom
# All rights reserved.
#
# Part of: hanaden-ai-booter
# Purpose: Manage the HANADEN-AI daemon lifecycle inside a vuniverse
#          (bwrap-enhanced, docker, podman, firejail, gvisor, systemd-nspawn)
#
# Usage:   hanaden-daemon [OPTIONS] COMMAND
# Commands: start|forcestart|stop|restart|forcerestart|reload|force-reload|status
#           list-backends|list-langs
#
# See:     boot/specs/design/1000-service-controller.md
# ============================================================================

readonly VERSION="0.0.1"
readonly AUTHOR="Frederick Bloom"
readonly COPYRIGHT="Copyright (c) 2026 Hanaden - ${AUTHOR}"
```

---

## Architecture

```
boot/
  hanaden-daemon               <- service controller (this design)
  vuniverse.sh                 <- vuniverse launcher (called by start)
  bwrap-enhanced.sh            <- one backend (existing, read-only)
  specs/                       <- config
```

Two-phase boot:
- **Phase 1 (AI):** Generate daemon source, validate syntax, write launch manifest
- **Phase 2 (mechanical):** `boot/vuniverse.sh` reads manifest, selects backend, execs

The service controller wraps Phase 2 with full LSB lifecycle management.

---

## Commands

### start

```pseudocode
1. Check: HOST PID file exists and process alive? -> "already running", exit 0
2. Resolve: HANADEN_CONV_ID (from env, or generate UUIDv7)
3. Resolve: EPHEMERAL_HOME from formula
4. Pre-seed: mkdir -p EPHEMERAL_HOME/home/sandbox-user
5. Resolve: daemon source
   - If DAEMON_SOURCE is set -> use it (pre-built binary or pre-generated script)
   - If daemon file exists at expected path -> use it
   - Else -> FATAL "No daemon source. Generate with AI agent or set DAEMON_SOURCE="
6. Write: launch.manifest (resolved from config)
7. Write: vuniverse.env (from config/0055)
8. Launch: vuniverse.sh launch.manifest (in background or foreground per -f)
9. Write: HOST PID to RUN_DIR/<CONV_ID>.pid
10. Wait: for daemon.pid to appear (up to HANDSHAKE_TIMEOUT)
11. Report: "hanaden-daemon started"
```

### forcestart

```pseudocode
1. If HOST PID file exists -> kill it (SIGKILL), remove PID file
2. Clean: rm -rf EPHEMERAL_HOME (fresh start)
3. Run: start
```

### stop

```pseudocode
1. Check: HOST PID file -> if not found, "not running", exit 0
2. Read: HOST PID
3. Signal: SIGTERM to backend process
4. Wait: SIGTERM_TIMEOUT (2s) for graceful shutdown
5. Check: if still alive -> SIGKILL
6. Clean: remove HOST PID file
7. Optionally: rm -rf EPHEMERAL_HOME (configurable)
8. Report: "hanaden-daemon stopped"
```

### restart
`stop` then `start`

### forcerestart
`stop` (with SIGKILL) + clean EPHEMERAL_HOME + `start`

### reload

```pseudocode
1. Check: daemon running?
2. Send: "reload" command to daemon.stdin.fifo (or SIGHUP)
3. Wait: for daemon to acknowledge
4. Report: "hanaden-daemon reloaded"
```

### force-reload
Try `reload`. If fails -> `restart`.

### status

```pseudocode
1. Check HOST PID file -> "not running" (exit 3) or read PID
2. Check process alive (kill -0) -> "stale PID" (exit 1) or continue
3. Check daemon.pid inside EPHEMERAL_HOME -> "not booted yet" (exit 4) or read
4. Report:
   "hanaden-daemon is running
    Backend: bwrap-enhanced (PID 12345)
    Daemon:  PID 67890
    Lang:    python
    Env:     dev
    Conv:    cc61ee22-...
    Uptime:  2h 15m
    Regens:  3"
5. Exit: 0
```

### list-backends

```
Available vuniverse backends:

  BACKEND           STATUS      PATH
  bwrap-enhanced    available   /path/to/boot/bwrap-enhanced.sh
  bwrap             available   /usr/bin/bwrap
  docker            available   /usr/bin/docker
  podman            not found   -
  firejail          available   /usr/bin/firejail
  gvisor            not found   -
  systemd-nspawn    available   /usr/bin/systemd-nspawn

Active: bwrap-enhanced (locked, from config)
```

### list-langs

```
Available language profiles:

  LANG            STARTUP     COMPILED    PROFILE
  python          instant     no          config/0050-lang-profile-python.md
  rust            slow-first  yes         config/0050-lang-profile-rust.md
  rust-script     moderate    no          config/0050-lang-profile-rust-script.md
  go              moderate    yes         config/0050-lang-profile-go.md
  zig             slow-first  yes         config/0050-lang-profile-zig.md

Active: python (locked, from config)
```

---

## CLI Interface

```
Usage: hanaden-daemon [OPTIONS] COMMAND

Commands:
  start           Start the daemon (skip if already running)
  forcestart      Kill existing, clean state, start fresh
  stop            Graceful shutdown (SIGTERM -> wait -> SIGKILL)
  restart         stop + start
  forcerestart    stop + clean EPHEMERAL_HOME + start
  reload          Hot-reload config without restart
  force-reload    Try reload, fall back to restart on failure
  status          Show daemon state, PIDs, uptime, regen count
  list-backends   List available vuniverse backends and probe status
  list-langs      List available language profiles and probe status

Options:
  -b, --backend=NAME       Override vuniverse backend
  -l, --lang=NAME          Override daemon language
  -e, --env=ENV            Override environment (dev|prod)
  -c, --conv-id=ID         Set conversation ID (default: auto UUIDv7)
  -d, --daemon-source=PATH Path to pre-built daemon binary/source
  -p, --project-home=PATH  Override PROJECT_HOME (default: auto-detect)
  -f, --foreground         Run in foreground (don't daemonize)
  -v, --verbose            Verbose output
  -q, --quiet              Suppress non-error output
  -h, --help               Show this help
  -V, --version            Show version

Environment Variables (lower priority than CLI flags):
  HANADEN_BACKEND          Same as --backend
  HANADEN_LANG             Same as --lang
  HANADEN_ENV              Same as --env (default: dev)
  HANADEN_CONV_ID          Same as --conv-id
  DAEMON_SOURCE            Same as --daemon-source
  PROJECT_HOME             Same as --project-home

Exit Codes (LSB):
  0    Success
  1    Generic error / dead but PID exists
  2    Invalid arguments
  3    Not running (status only)
  4    Subsystem locked
```

### Priority Chain (highest wins)

```
1. CLI flag      --backend=docker
2. Env var       HANADEN_BACKEND=docker
3. Config        config/0058-vuniverse-backend.md [backend.<env>].backend_locked
4. Fallback      first-available from backends_allowed
```

---

## PID Management

```
EPHEMERAL_HOME/
  daemon.pid              <- written by daemon at boot (PID inside vuniverse)
  daemon.stdin.fifo       <- FIFO for commands
  daemon.stdout.log       <- stdout log
  daemon.stderr.log       <- stderr log
  launch.manifest         <- written by start, used by restart
  vuniverse.env           <- env file for the vuniverse
  home/sandbox-user/      <- sandbox-user writable home
    <daemon source>       <- per lang profile filename

RUN_DIR = ${XDG_RUNTIME_DIR:-/run}/hanaden-ai/
  <CONV_ID>.pid           <- HOST-side PID of the backend process
  <CONV_ID>.manifest      <- symlink to EPHEMERAL_HOME/launch.manifest
```

---

## Signal Routing

```
Terminal/systemd -> hanaden-daemon stop
  -> SIGTERM to backend HOST PID
    -> backend forwards SIGTERM to daemon (PID 1 inside vuniverse)
      -> daemon: graceful shutdown (SHUTTING_DOWN -> TERMINATED)
      -> daemon exits
    -> backend exits
  -> hanaden-daemon removes PID file
```

For bwrap: SIGTERM goes direct (daemon IS PID 1 inside bwrap).
For docker: `docker stop` sends SIGTERM then SIGKILL after timeout.
For firejail: firejail forwards signals.

---

## Launch Manifest

Contract between Phase 1 (AI) and Phase 2 (vuniverse.sh). Simple key=value
file that bash can `source`. No TOML parser needed.

```bash
# EPHEMERAL_HOME/launch.manifest
BACKEND=bwrap-enhanced
BACKEND_BINARY=PROJECT_HOME/boot/bwrap-enhanced.sh
LANG=python
ENTRY_CMD=/home/sandbox-user/daemon.py
EPHEMERAL_HOME=/tmp/hanaden-ai/cc61ee22-.../pid-12345
PROJECT_HOME=/path/to/hanaden-ai-booter/PROJECT_HOME
VUNIVERSE_ENV_FILE=EPHEMERAL_HOME/vuniverse.env
MOUNT_COUNT=8
# ... mount entries per config/0060-vuniverse-fs.md
```

---

## systemd Unit Template

```ini
# /etc/systemd/system/hanaden-daemon@.service
[Unit]
Description=HANADEN-AI Daemon (conversation %i)
After=network.target

[Service]
Type=forking
Environment=HANADEN_ENV=prod
Environment=HANADEN_CONV_ID=%i
Environment=DAEMON_SOURCE=/usr/local/lib/hanaden/daemon
PIDFile=/run/hanaden-ai/%i.pid
ExecStart=/usr/local/lib/hanaden/boot/hanaden-daemon start
ExecStop=/usr/local/lib/hanaden/boot/hanaden-daemon stop
ExecReload=/usr/local/lib/hanaden/boot/hanaden-daemon reload
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## Callers

```
Terminal:  boot/hanaden-daemon start
AI agent:  Phase 1 (generate source) -> boot/hanaden-daemon start
systemd:   ExecStart=boot/hanaden-daemon start
```

One entry point, three callers, same behavior.
