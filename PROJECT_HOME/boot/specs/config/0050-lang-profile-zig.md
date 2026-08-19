<!-- (c) 2026-* Frederick Bloom -- 0050-lang-profile-zig.md -- Hanaden AI -->

## Language Profile: Zig

```toml
[profile]
lang              = "zig"
interpreter       = ""
filename          = "daemon"
file_ext          = ".zig"
entry_cmd         = "/home/sandbox-user/daemon"
syntax_check_cmd  = "zig build --check {file}"
event_loop        = "std.io.poll (epoll, zero-poll)"
inotify_binding   = "std.os.linux.inotify or @cImport"
process_replace   = "std.posix.execve()"
compiled          = true
stdlib_only       = true
startup_class     = "slow-first"
```
