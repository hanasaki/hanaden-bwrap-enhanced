---
filename-id: DesktopIntegrationEngine.arch
node-type: ARCH
layer: 1
version: 0.3.0
author: Frederick Bloom
copyright: (c) 2026-* Frederick Bloom
description: "Desktop Integration Engine -- GUI, audio, a11y, D-Bus, DE passthrough"
parent: 20260830-025304-995277-7a65-ad8b-97b85fbd71e6-NamespaceIsolatedSandbox.moti
---

# DesktopIntegrationEngine

## Purpose
Manages desktop environment passthrough: X11, Wayland, audio (PipeWire/Pulse),
accessibility (AT-SPI), D-Bus session bus, GNOME services, KDE services,
environment sanitization, and network isolation.

## Feature Tree

```mermaid
graph TD
    DIE["DesktopIntegrationEngine.arch"]
    GP["GuiPassthrough.feat"]
    AP["AudioPassthrough.feat"]
    A11["A11yPassthrough.feat"]
    DP["DbusPassthrough.feat"]
    GN["GnomePassthrough.feat"]
    KD["KdePassthrough.feat"]
    ES["EnvSanitization.feat"]
    NI["NetworkIsolation.feat"]
    DIE --> GP & AP & A11 & DP & GN & KD & ES & NI
```

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.3.0 | 2026-08-30 | Frederick Bloom + AI | Initial |
