
## 9. Signal Handling

```bash
DAEMON_PID=$(cat $EHOME/daemon.pid)
kill -TERM $DAEMON_PID    # graceful stop
kill -KILL $DAEMON_PID    # force kill (last resort)
```

SIGTERM/SIGINT handler:
1. Emit `phase=SHUTTING_DOWN`
2. Drain stdin max 1s
3. Kill persistent bash
4. Emit `phase=TERMINATED daemon=HALTED term_code=0`
5. Flush all logs, exit(0)

---
