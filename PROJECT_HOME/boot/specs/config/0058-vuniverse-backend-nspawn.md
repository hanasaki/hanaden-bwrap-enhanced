<!-- (c) 2026-* Frederick Bloom -- 0058-vuniverse-backend-nspawn.md -- Hanaden AI -->

## Vuniverse Backend Profile: systemd-nspawn

```toml
[profile]
name              = "nspawn"
binary            = "systemd-nspawn"
binary_check_cmd  = "systemd-nspawn --version"
description       = "systemd-nspawn lightweight container. Requires root or polkit."

[flags]
clear_env         = "--setenv=HOME=/home/sandbox-user"    # nspawn clears env by default
bind_ro           = "--bind-ro={src}:{dst}"
bind_rw           = "--bind={src}:{dst}"
set_env           = "--setenv={key}={value}"
entry_separator   = ""

[capabilities]
signal_forwarding = true
pid_namespace     = true
network_isolation = false      # depends on --network-*
tmpfs_on_tmp      = true       # default
```
