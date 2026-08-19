<!-- (c) 2026-* Frederick Bloom -- 0800-log-rotation.md -- Hanaden AI -->

## 8. Log Rotation

See `hanaden-ai-daemon.config.md` for parameters.

```
Trigger:    daemon.stdout.log size >= LOG_ROTATION_TRIGGER_SIZE (default 10MB)
Keep:       LOG_ROTATION_KEEP rotated copies (default 4)
Algorithm:  copytruncate
Compress:   gzip in background thread (MUST-NOT block event loop)
Check:      every LOG_ROTATION_CHECK_INTERVAL events (default 100)
```

---
