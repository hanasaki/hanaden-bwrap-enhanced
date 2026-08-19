<!-- (c) 2026-* Frederick Bloom -- 0058-vuniverse-backend-gvisor.md -- Hanaden AI -->

## Vuniverse Backend Profile: gVisor (runsc)

```toml
[profile]
name              = "gvisor"
binary            = "runsc"
binary_check_cmd  = "runsc --version"
description       = "gVisor user-space kernel sandbox. Used via Docker/Podman --runtime=runsc or standalone."

[flags]
# gVisor is typically used as a Docker/Podman runtime, not standalone.
# When standalone: OCI bundle spec required.
clear_env         = ""
bind_ro           = ""          # via OCI spec mounts
bind_rw           = ""          # via OCI spec mounts
set_env           = ""          # via OCI spec env
entry_separator   = ""

[capabilities]
signal_forwarding = true
pid_namespace     = true
network_isolation = true
tmpfs_on_tmp      = true
```
