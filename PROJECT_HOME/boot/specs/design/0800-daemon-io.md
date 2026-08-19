<!-- (c) 2026-* Frederick Bloom -- 0800-daemon-io.md -- Hanaden AI -->
# 10. Daemon I/O Connectivity

The daemon functions as the session I/O hub. Full protocol defined in
`hanaden-ai-daemon-cmdstream.design.md` (loaded by Step 1 before this pseudocode executes).

Key points:
* stdin via daemon.stdin.fifo (named FIFO, shared by all callers)
* stdout tee'd to daemon.stdout.log
* stderr tee'd to daemon.stderr.log
* pid written at phase=INITIALIZING
* Handshake protocol determines caller_mode (AI-CONNECTED / STANDALONE+SIDECAR / HEADLESS)
* ai-exec dispatch: via stdout.log<->FIFO (AI-CONNECTED) or piped subprocess (HEADLESS)
* Persistent bash subprocess (always) for OS command execution
* Persistent ai-exec subprocess (HEADLESS only) discovered by discover_sidecar()
* cd interception with jail guard
* Log rotation (copytruncate, gzip, 4 copies)

---

