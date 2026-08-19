<!-- (c) 2026-* Frederick Bloom -- 0058-vuniverse-backend-firejail.md -- Hanaden AI -->

## Vuniverse Backend Profile: Firejail

```toml
[profile]
name              = "firejail"
binary            = "firejail"
binary_check_cmd  = "firejail --version"
description       = "Firejail SUID sandbox. Lightweight, profile-based."

[flags]
clear_env         = ""                          # use --env=clear or profile
bind_ro           = "--read-only={src}"
bind_rw           = "--bind={src},{dst}"
set_env           = "--env={key}={value}"
entry_separator   = ""

[capabilities]
signal_forwarding = true
pid_namespace     = true       # default
network_isolation = false      # depends on profile
tmpfs_on_tmp      = false      # depends on profile
```
