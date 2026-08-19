<!-- (c) 2026-* Frederick Bloom -- 0200-core-and-readonly-files.md -- Hanaden AI -->

## Core Files (inotify-watched, change triggers reboot)

```
CORE_FILES = [
    /boot/hanaden-ai-daemon.design.md,
    /boot/hanaden-ai-daemon.config.md,
    /boot/hanaden-ai-daemon-cmdstream.design.md,
    /CONSTITUTION.md,
    /README.md,
]
```

## Read-Only Files (MUST-NOT edit, MUST-NOT chmod, MUST-NOT delete)

```
READONLY_FILES = [
    /boot/bwrap-enhanced.sh,
]
```
