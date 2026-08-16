
## Vuniverse Backend Profile: Podman

```toml
[profile]
name              = "podman"
binary            = "podman"
binary_check_cmd  = "podman --version"
description       = "Podman container backend. Rootless, daemonless. Same flag syntax as Docker."

[flags]
clear_env         = ""
bind_ro           = "-v {src}:{dst}:ro"
bind_rw           = "-v {src}:{dst}"
set_env           = "-e {key}={value}"
env_file          = "--env-file {path}"
entry_separator   = ""

[capabilities]
signal_forwarding = true
pid_namespace     = true
network_isolation = true
tmpfs_on_tmp      = false
```
