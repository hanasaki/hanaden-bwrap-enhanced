
## 7. Shell Session State

### 7a. session_cwd

```
Initial value:  daemon's CWD at startup (/home/hanaden-ai inside bwrap)
Mutated by:     cd <path> (raw passthrough, intercepted -- no subprocess)
Read by:        every exec invocation (cwd= argument to bash)
                status command (included in ACK)
                exec_done response (cwd field)
NOT mutated by: {"cmd":"exec","shell":"cd /foo"} (subprocess cd has no effect)
```

### 7b. cd Interception (Jail Guard)

```mermaid
flowchart TD
    CD(["Raw line: cd &lt;path&gt;"]) --> REL{"relative path?"}
    REL -->|yes| JOIN["join(session_cwd, path)"]
    REL -->|no| USE["use path as-is"]
    JOIN --> RP["realpath() -- resolve symlinks"]
    USE --> RP
    RP --> JAIL{"inside SANDBOX_ROOT?"}
    JAIL -->|no| ERR1["emit {ack:cd-error, reason:jail-escape}\nsession_cwd UNCHANGED"]
    JAIL -->|yes| ISDIR{"os.path.isdir()?"}
    ISDIR -->|no| ERR2["emit {ack:cd-error, reason:not-a-directory}\nsession_cwd UNCHANGED"]
    ISDIR -->|yes| OK["session_cwd = realpath\nemit {ack:cd, cwd:newpath, ts_ns}"]
```

### 7c. Reboot Behavior

On Reboot, session_cwd resets to daemon's initial CWD.

---
