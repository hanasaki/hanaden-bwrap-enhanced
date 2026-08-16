
## ai-exec Dispatch

```
AI_EXEC_TIMEOUT             = 120s                 # max wait per ai-exec request
AI_EXEC_BATCH_MODE          = sequential           # sequential | concurrent
AI_EXEC_QUEUE_ON_NO_AI      = true                 # queue ai-exec files when no AI connected
```

## Handshake

```
HANDSHAKE_TIMEOUT           = 2s                   # max wait for handshake before defaulting to headless
```

## Persistent Bash

```
BASH_PATH                   = /bin/bash            # path to bash inside jail
BASH_PROMPT_SENTINEL        = __HANADEN_CMD_DONE__ # sentinel for command completion detection
BASH_COMMAND_TIMEOUT        = 300s                 # max execution time per command (5 min)
```
