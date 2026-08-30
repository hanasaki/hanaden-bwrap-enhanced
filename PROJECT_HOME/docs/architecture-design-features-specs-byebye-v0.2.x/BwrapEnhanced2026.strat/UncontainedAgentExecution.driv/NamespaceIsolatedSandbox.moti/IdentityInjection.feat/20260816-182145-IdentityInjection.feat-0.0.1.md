<!-- (c) 2026-* Frederick Bloom -- IdentityInjection.feat-0.0.1.md -- Hanaden AI Loader -->
---
filename-id:   20260816-182145-IdentityInjection.feat
node-type:     FEAT
layer:         2
version:       0.0.1
status:        Implemented
author:        Frederick Bloom
copyright:     (c) 2026-* Frederick Bloom
parent:        20260816-182145-NamespaceIsolatedSandbox.moti
description: >
  Feature: Synthetic /etc/passwd, /etc/group, /etc/profile injected via bwrap
  --ro-bind-data on bash FDs 9, 10, 11. No host disk writes. Passwd includes
  system accounts (UID<1000) + virtual user (host UID). Group mirrors same.
---

# IdentityInjection: Synthetic Identity Files via FD Injection

## Rationale

The sandbox needs a coherent `/etc/passwd` and `/etc/group` for `getpwuid()`, `id`,
`whoami`, and group membership checks to work. Writing temp files creates a race
condition window. FD-based injection via bash here-strings is atomic and leaves
zero trace on disk.

## Feature Overview

```mermaid
graph TD
    F[\"IdentityInjection.feat\"]
    F --> PSC["PasswdSystemClone.spec<br/>UID<1000 cloned"]
    F --> PVU["PasswdVirtualUser.spec<br/>VUSER:x:HOST_UID:HOST_GID"]
    F --> GSC["GroupSystemClone.spec<br/>GID<1000 cloned"]
    F --> MP["MinimalProfile.spec<br/>PATH only"]
    F --> FDI["FdInjection.spec<br/>--ro-bind-data 9 10 11"]
```

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2026-08-16 | Frederick Bloom + AI | Initial |
| 0.0.1 | 2026-08-17 | Frederick Bloom + AI | Enriched |
