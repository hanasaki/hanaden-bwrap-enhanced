
## Vuniverse Backend Profile: bwrap (raw bubblewrap)

```toml
[profile]
name              = "bwrap"
binary            = "/usr/bin/bwrap"
binary_check_cmd  = "bwrap --version"
description       = "Raw bubblewrap without bwrap-enhanced.sh wrapper. Manual flag construction."

[flags]
clear_env         = "--clearenv"
host_root         = ""                    # no equivalent — must manually bind /
bind_ro           = "--ro-bind {src} {dst}"
bind_rw           = "--bind {src} {dst}"
mkdir             = "--dir {path}"
set_env           = "--setenv {key} {value}"
entry_separator   = "--"

[capabilities]
signal_forwarding = true
pid_namespace     = false
network_isolation = false
tmpfs_on_tmp      = false                 # must add --tmpfs /tmp manually if needed
tmpfs_on_homes    = false                 # must add --tmpfs /homes manually if needed
```
