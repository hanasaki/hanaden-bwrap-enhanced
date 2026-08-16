---

## 5. ai-exec Dispatch Protocol

When the daemon discovers or processes an AI_SHEBANG file, it dispatches to
the connected AI agent or sidecar. The daemon cannot interpret ai-exec files
itself -- it needs an LLM.

### 5a. ai-exec Request (daemon -> AI/sidecar via stdout)

```json
{
    "request": "ai-exec",
    "id": "req-<uuid4-short>",
    "path": "/boot/hanaden-ai-daemon.design.md",
    "shebang_params": {"flow_type": "PSEUDOCODE"},
    "content": "<full UTF-8 file content>",
    "context": {
        "phase": "BOOTING",
        "session_cwd": "/home/hanaden-ai",
        "caller_mode": "ai-connected",
        "core_files_ok": true
    },
    "ts_ns": 0
}
```

### 5b. ai-exec Response (AI/sidecar -> daemon via FIFO)

```json
{
    "response": "ai-exec",
    "id": "req-<uuid4-short>",
    "status": "ok",
    "result": {
        "handlers_registered": ["onEventBoot", "onEventBootBefore"],
        "output": "<text output from processing>"
    },
    "ts_ns": 0
}
```

**Error response:**
```json
{
    "response": "ai-exec",
    "id": "req-<uuid4-short>",
    "status": "error",
    "error": {"code": "PARSE_FAILURE", "message": "Failed at line 42"},
    "ts_ns": 0
}
```

### 5c. Timeout

Daemon waits `AI_EXEC_TIMEOUT` (default 120s) for each ai-exec response.
On timeout: LOGGER.error, request marked failed, boot continues.

### 5d. Batch Processing

ai-exec files discovered during boot are dispatched SEQUENTIALLY (order matters
for event handler registration). OS shebang files can run concurrently.

### 5e. Headless Queue

When no AI processor is connected, ai-exec files are QUEUED. When a handshake
arrives later, the queue drains in order.

---
