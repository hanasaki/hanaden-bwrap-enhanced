<!-- (c) 2026-* Frederick Bloom -- 0300-shebang-inotify.md -- Hanaden AI -->

## Shebang Patterns

```
AI_EXEC_SHEBANG_REGEX       = "^<!\-\-\\s*#!(?:/usr/bin/env\\s+)?ai-exec(?:\\s+(?P<params>[^-].*?))?\s*-->"
OS_SHEBANG_REGEX            = "^#!/.*"
```

## Implicit AI Files (no shebang required -- always classified as AI_SHEBANG)

```
IMPLICIT_AI_FILES = [
    README.md,              # in any directory
    CONSTITUTION.md,        # in jail root only
]
```

## inotify Configuration

```
INOTIFY_BACKEND             = ctypes              # stdlib only, no pip
INOTIFY_WATCH_MASK          = IN_CREATE | IN_DELETE | IN_MODIFY | IN_CLOSE_WRITE | IN_MOVED_FROM | IN_MOVED_TO | IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF
INOTIFY_OVERFLOW_ACTION     = full-rescan          # on IN_Q_OVERFLOW: rescan entire tree
INOTIFY_MOVE_COOKIE_TIMEOUT = 1s                   # max wait for IN_MOVED_TO after IN_MOVED_FROM
```
