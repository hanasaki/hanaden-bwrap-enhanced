
## Language Profile: Rust-Script

Rust source executed directly via `cargo -Z script` — no separate compile step,
single-file, interpreter-style. Same language as `rust` but fundamentally different
execution model.

```toml
[profile]
lang              = "rust-script"
interpreter       = "cargo"
filename          = "daemon.rs"
file_ext          = ".rs"
entry_cmd         = "cargo +nightly -Zscript /home/sandbox-user/daemon.rs"
shebang           = "#!/usr/bin/env cargo +nightly -Z script"
syntax_check_cmd  = "cargo +nightly -Zscript --check {file}"
event_loop        = "tokio (epoll, zero-poll)"
inotify_binding   = "inotify crate or libc::inotify_*"
process_replace   = "exec::execv() (nix crate)"
compiled          = false
stdlib_only       = false
startup_class     = "moderate"
```
