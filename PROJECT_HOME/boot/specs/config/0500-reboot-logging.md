
## Reboot Teardown

```
REBOOT_SUBPROC_SIGTERM_WAIT = 2s                   # wait after SIGTERM before SIGKILL
REBOOT_PHASES               = P1,P2,P3,P4,P4a,P5,P6  # P4a = kill owned subprocesses
```

## Log Rotation (matching Linux syslog/logrotate defaults)

```
LOG_ROTATION_TRIGGER_SIZE   = 10MB                 # rotate when daemon.stdout.log >= this
LOG_ROTATION_KEEP           = 4                    # number of rotated copies (.1.gz through .4.gz)
LOG_ROTATION_ALGORITHM      = copytruncate         # copy then truncate in-place
LOG_ROTATION_COMPRESS       = gzip                 # compress rotated copies
LOG_ROTATION_CHECK_INTERVAL = 100                  # check every N events
```

## Logging (SLF4J/Logback compliant)

```
LOGGER_DEFAULT_LEVEL        = WARN                 # default log level
LOGGER_INTERACTIVE_LEVEL    = INFO                 # log level in TTY interactive mode
LOGGER_PATTERN              = [%d{yyyy-MM-dd'T'HH:mm:ss.SSSSSS}] [%-5level] [%X{project}.%F.%M:%L] %msg%n
```

```xml
<!-- logback.xml -->
<configuration>
  <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>[%d{yyyy-MM-dd'T'HH:mm:ss.SSSSSS}] [%-5level] [%X{project}.%F.%M:%L] %msg%n</pattern>
    </encoder>
  </appender>
  <root level="INFO">
    <appender-ref ref="CONSOLE"/>
  </root>
</configuration>
```
