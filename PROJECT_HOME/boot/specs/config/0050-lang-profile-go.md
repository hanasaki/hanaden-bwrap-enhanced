<!-- (c) 2026-* Frederick Bloom -- 0050-lang-profile-go.md -- Hanaden AI -->

## Language Profile: Go

```toml
[profile]
lang              = "go"
interpreter       = ""
filename          = "daemon"
file_ext          = ".go"
entry_cmd         = "/home/sandbox-user/daemon"
syntax_check_cmd  = "go vet {file}"
event_loop        = "goroutine + epoll (zero-poll)"
inotify_binding   = "fsnotify or syscall.InotifyInit1()"
process_replace   = "syscall.Exec()"
compiled          = true
stdlib_only       = false
startup_class     = "moderate"
```
