<!-- (c) 2026-* Frederick Bloom -- NetworkIsolation.feat-0.0.1.md -- Hanaden AI Loader -->
---
filename-id:   20260816-182145-NetworkIsolation.feat
node-type:     FEAT
layer:         2
version:       0.0.1
status:        Implemented
author:        Frederick Bloom
copyright:     (c) 2026-* Frederick Bloom
parent:        20260816-182145-NamespaceIsolatedSandbox.moti
description: >
  Feature: Default-deny network via --unshare-net. --share-net opt-in with WARNING.
  resolv.conf and nsswitch.conf always bound RO for DNS correctness.
---

# NetworkIsolation: Default-Deny Network with Explicit Opt-In

## Rationale

Network access is the highest-risk capability for AI agents. A default-deny policy
means callers must explicitly opt-in, creating a natural audit trail (--share-net
appears in logs). The WARNING on stderr ensures visibility in CI pipelines.

## Feature Overview

```mermaid
graph TD
    F[\"NetworkIsolation.feat\"]
    F --> ND["NetworkDeny.spec<br/>--unshare-net default"]
    F --> SNO["ShareNetOptIn.spec<br/>--share-net + WARNING"]
```

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2026-08-16 | Frederick Bloom + AI | Initial |
| 0.0.1 | 2026-08-17 | Frederick Bloom + AI | Enriched |
