<!-- (c) 2026-* Frederick Bloom -- 0200-caller-mode-detection.md -- Hanaden AI -->

## 2. Caller Mode Detection

The daemon auto-detects its caller mode at startup.

```mermaid
flowchart TD
    START(["Daemon starts"]) --> TTY{"os.isatty(stdin)?"}
    TTY -->|yes| TTYM["TTY INTERACTIVE MODE\nUser at keyboard\nOS cmds -> screen\nai-exec -> sidecar if present, else QUEUE"]
    TTY -->|no| HS{"Handshake received\nwithin HANDSHAKE_TIMEOUT?"}
    HS -->|ai-agent| AIC["AI-CONNECTED MODE\nai-exec -> stdout.log\nAI responds via FIFO"]
    HS -->|ai-exec-runner| SCS["STANDALONE+SIDECAR MODE\nai-exec -> runner via FIFO\nbash -> screen"]
    HS -->|timeout / no msg| HDL["HEADLESS MODE\nOS cmds work\nai-exec -> sidecar subprocess\nor QUEUED if none"]
```

### Handshake Protocol

The FIRST message a caller writes to the FIFO is a handshake:

**AI Agent handshake:**
```json
{"handshake": "ai-agent", "capabilities": ["ai-exec"], "model": "gemini-2.5-pro", "ts_ns": 0}
```

**ai-exec-runner sidecar handshake:**
```json
{"handshake": "ai-exec-runner", "capabilities": ["ai-exec"], "provider": "gemini-cli", "ts_ns": 0}
```

**Daemon ACK:**
```json
{"ack": "handshake", "mode": "ai-connected", "phase": "BOOTING", "ts_ns": 0}
```

#### Handshake Sequence (MSC)

```mermaid
sequenceDiagram
    participant C  as Caller (AI Agent / Runner)
    participant F  as daemon.stdin.fifo
    participant D  as daemon
    participant L  as daemon.stdout.log

    Note over D: phase=INITIALIZING -> BOOTING
    D  ->> F  : open(fifo, O_RDONLY | O_NONBLOCK)
    C  ->> F  : {handshake: ai-agent, capabilities, model, ts_ns}
    F  ->> D  : deliver line (within HANDSHAKE_TIMEOUT=2s)
    D  ->> D  : set caller_mode = ai-connected
    D  ->> L  : {ack: handshake, mode: ai-connected, phase: BOOTING, ts_ns}
    L  ->> C  : reads via tail -F

    Note over D: HEADLESS fallback (no msg in 2s)
    D  ->> D  : set caller_mode = headless
    D  ->> D  : discover_sidecar() -> spawn if found
```

---
