
## Language Profile: Python

```toml
[profile]
lang              = "python"
interpreter       = "python3"
filename          = "daemon.py"
file_ext          = ".py"
entry_cmd         = "python3 /home/sandbox-user/daemon.py"
syntax_check_cmd  = "python3 -m py_compile {file}"
event_loop        = "asyncio (epoll, zero-poll)"
inotify_binding   = "ctypes (stdlib only)"
process_replace   = "os.execv()"
stdlib_only       = true
startup_class     = "instant"

[anti_regression]
mandates = [
    "MUST use asyncio with loop.connect_read_pipe() for stdin",
    "MUST register inotify via ctypes (stdlib only, no pip)",
    "MUST add inotify fd via loop.add_reader(inotify_fd, handler)",
    "MUST-NOT use select.select() with any timeout value",
    "Omitting asyncio event loop or substituting polling is FATAL",
]
```
