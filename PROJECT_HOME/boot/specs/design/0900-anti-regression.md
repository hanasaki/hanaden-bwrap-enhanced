# 11. Anti-Regression Mandates

* AI MUST implement the event loop per the active lang profile's event_loop specification.
* AI MUST register inotify watches per the active lang profile's inotify_binding specification.
* AI MUST obey all mandates in the active lang profile's [anti_regression] section.
* inotify fd MUST be added to the event loop (zero-poll, never timeout-based).
* AI MUST-NOT use `tail -f /dev/null` as FIFO write-end holder. MUST use `sleep infinity > fifo &`.
* On `readline()` returning "" (EOF): emit SHUTTING_DOWN then TERMINATED term_code=1, exit(1).
* Omitting the event loop or substituting a polling script is FATAL.
* Self-regen MUST use `execve()` with explicit envp -- MUST-NOT use subprocess restart or graceful shutdown.
* `execve()` preserves all open FDs (FIFO, logs, bash pipes, sidecar pipes). MUST-NOT close them before exec.
* Persistent subprocess registry (`self._subprocesses`) MUST be used for ALL subprocess lifecycle ops.
* `"ai-exec"` subprocess MUST-NOT be spawned in AI-CONNECTED or STANDALONE+SIDECAR modes.
* Reboot (P4b) MUST create a new ephemeral dir. Self-regen MUST-NOT create a new ephemeral dir.
* Backend-specific mandates (host-real-root, ro-bind, pre-seed) -> see active backend profile `config/0058-vuniverse-backend-*.md [anti_regression]`.
