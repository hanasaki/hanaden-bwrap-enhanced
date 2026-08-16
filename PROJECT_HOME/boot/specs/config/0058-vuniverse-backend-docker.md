
## Vuniverse Backend Profile: Docker

```toml
[profile]
name              = "docker"
binary            = "docker"
binary_check_cmd  = "docker --version"
description       = "Docker container backend. Requires a base image."

[flags]
clear_env         = ""                        # docker clears env by default
bind_ro           = "-v {src}:{dst}:ro"
bind_rw           = "-v {src}:{dst}"
set_env           = "-e {key}={value}"
env_file          = "--env-file {path}"
entry_separator   = ""                        # no separator, image then cmd

[capabilities]
signal_forwarding = true       # docker stop sends SIGTERM -> SIGKILL
pid_namespace     = true
network_isolation = true       # default bridge network
tmpfs_on_tmp      = false      # must add --tmpfs /tmp if needed
```
