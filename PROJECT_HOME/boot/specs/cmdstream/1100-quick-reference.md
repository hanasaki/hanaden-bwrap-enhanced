<!-- (c) 2026-* Frederick Bloom -- 1100-quick-reference.md -- Hanaden AI -->

## Quick Reference Card

```
CHANNEL                    PATH (relative to EPHEMERAL_HOME)
--------------------------------------------------------------
Input (write to daemon)    daemon.stdin.fifo
Output (read from daemon)  daemon.stdout.log  (tail -F)
Errors                     daemon.stderr.log  (tail -F)
Daemon PID                 daemon.pid         (cat)

ARCHITECTURE               SPEC FILE
--------------------------------------------------------------
Command executor           0350-cmd-executor.md
Exec return processing     0360-exec-return-processing.md
JSON command processor     0370-cmd-processor-json.md
Terminal IO processor      0380-terminal-io-processor.md
Wire format (JSON:API)     0400-wire-format.md

JSON COMMANDS              INPUT
--------------------------------------------------------------
Handshake                  {"handshake":"ai-agent","capabilities":["ai-exec"],...}
Status                     {"cmd":"status"}
Set log level              {"cmd":"loglevel","level":"INFO"}
List handlers              {"cmd":"handlers"}
Shutdown                   {"cmd":"shutdown"}
Exec (structured)          {"cmd":"exec","shell":"<cmd>","ts_ns":0}
Fire UserTurn              {"event":"UserTurn","ts_ns":0}
Fire AiTurn                {"event":"AiTurn","ts_ns":0}
Fire Reboot                {"event":"Reboot","ts_ns":0}
ai-exec response           {"response":"ai-exec","id":"<id>","status":"ok",...}

TTY SHORTCUTS              JSON EQUIVALENT
--------------------------------------------------------------
status                     {"cmd":"status"}
reboot                     {"event":"Reboot","ts_ns":0}
shutdown / quit            {"cmd":"shutdown"}
handlers                   {"cmd":"handlers"}
debug / info / warn        {"cmd":"loglevel","level":"<LEVEL>"}
help                       (prints help text)
<any other text>           {"cmd":"exec","shell":"<text>","ts_ns":0}

EXEC RESPONSE — SUCCESS
--------------------------------------------------------------
Streaming stdout line      {"ack":"exec_line","line":"...","ts_ns":0}
Streaming stderr line      {"ack":"exec_err_line","line":"...","ts_ns":0}
Command done               {"ack":"exec_done","exit_code":0,"cwd":"...","ts_ns":0}

EXEC RESPONSE — FAILURE (JSON:API error object, per 0360 + 0400)
--------------------------------------------------------------
Command done (failure)     {"ack":"exec_done","exit_code":N,"cwd":"...",
                            "error":{"code":"CD-FAILED",
                                     "title":"cd to session_cwd failed",
                                     "detail":"cd: /path: No such file or dir",
                                     "source":{"step":"cd_session_cwd","command":"..."},
                                     "meta":{"stderr":"..."}},
                            "ts_ns":0}

STANDARD ERROR CODES (0400-wire-format.md)
--------------------------------------------------------------
CD-FAILED                  cd to session_cwd failed
BASH-PIPE-BROKEN           bash stdin pipe broken
BASH-EXITED                bash exited unexpectedly
TIMEOUT                    command execution timed out
JAIL-ESCAPE                path resolves outside sandbox root
NOT-A-DIRECTORY            cd target is not a directory
COMMAND-FAILED             command returned non-zero exit code
UNKNOWN-CMD                unrecognized command
UNKNOWN-EVENT              unrecognized event name
PARSE-FAILURE              ai-exec file parse failed
INTERNAL                   internal daemon error

ERROR OBJECT FIELDS        MANDATE (0360-exec-return-processing.md)
--------------------------------------------------------------
error.code                 MUST  - SCREAMING-KEBAB from standard codes
error.detail               MUST  - occurrence-specific human explanation
error.meta.stderr          MUST  - verbatim stderr (or "")
error.source.step          SHOULD - internal step that failed
error.title                SHOULD - stable one-liner (from code table)

OUTPUT FORMAT              DETERMINED BY
--------------------------------------------------------------
ai-connected mode          JSON-Lines always
headless mode              JSON-Lines always
tty mode                   Console text via terminal-io-processor (0380)

ai-exec request            {"request":"ai-exec","id":"...","path":"...","content":"..."}
Error ACK                  {"ack":"error","error":{"code":"...","detail":"..."},"ts_ns":0}
```
