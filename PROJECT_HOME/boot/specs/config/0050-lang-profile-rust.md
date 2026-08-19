<!-- (c) 2026-* Frederick Bloom -- 0050-lang-profile-rust.md -- Hanaden AI -->

## Language Profile: Rust

```toml
[profile]
lang              = "rust"
interpreter       = ""
filename          = "daemon"
file_ext          = ".rs"
entry_cmd         = "/home/sandbox-user/daemon"
syntax_check_cmd  = "rustc --edition 2024 --check {file}"
event_loop        = "tokio (epoll, zero-poll)"
inotify_binding   = "inotify crate or libc::inotify_*"
process_replace   = "exec::execv() (nix crate)"
compiled          = true
stdlib_only       = false
startup_class     = "slow-first"
```
