# Open-Source License Comparison: Features Matrix & Selection Criteria
<!-- Source: PROJECT_HOME/docs/legal/third-party/opensource/ — 27 license texts -->
<!-- Scope: open-source distribution licenses only. See ../contributor-license-agreement/ for CLA analysis. -->

> **Scope:** Generic analysis of the 27 OSI-recognized licenses present in the corpus.  
> No project-specific context is included.
>
> **Research & synthesis:** Prior session — Claude Sonnet 4.6 (corpus reading, legal text analysis, matrix population).  
> **Revision:** Claude Sonnet 4.6 (diagram layout & colour corrections).

---

## 1 · Taxonomy Diagrams

### 1.1 · Permissive ↔ Restrictive Spectrum (Tree)

```mermaid
graph LR
    ROOT(["🔓 Open-Source Licenses"])

    ROOT --> PD
    ROOT --> PERM
    ROOT --> WEAK
    ROOT --> STRONG
    ROOT --> NET
    ROOT --> SPEC

    subgraph PD ["① Public Domain / No-Rights"]
        direction TB
        Unlicense["Unlicense"]
        CC0["CC0-1.0"]
        ZEROBSD["0BSD"]
        MIT0["MIT-0"]
    end

    subgraph PERM ["② Permissive"]
        direction TB
        ISC["ISC"]
        MIT["MIT"]
        BSD1["BSD-1-Clause"]
        BSD2["BSD-2-Clause"]
        Zlib["Zlib"]
        PG["PostgreSQL"]
        BSD3["BSD-3-Clause"]
        AFL["AFL-3.0 ★pat"]
        Apache["Apache-2.0 ★pat"]
        MSPL["MS-PL ★pat"]
    end

    subgraph WEAK ["③ Weak / File-Level Copyleft"]
        direction TB
        MPL["MPL-2.0"]
        CDDL["CDDL-1.0"]
        EPL["EPL-2.0"]
        CPL["CPL-1.0"]
        LGPL21["LGPL-2.1"]
        LGPL3["LGPL-3.0"]
    end

    subgraph STRONG ["④ Strong / Program-Level Copyleft"]
        direction TB
        GPL2["GPL-2.0"]
        GPL3["GPL-3.0 ★TiVo"]
        OSL["OSL-3.0"]
        EUPL["EUPL-1.2"]
    end

    subgraph NET ["⑤ Network / SaaS Copyleft"]
        direction TB
        AGPL["AGPL-3.0 ★TiVo"]
    end

    subgraph SPEC ["⑥ Specialized Domain"]
        direction TB
        OFL["OFL-1.1 — Fonts"]
        FDL["FDL-1.3 — Docs"]
    end

    style PD    fill:#1a3a5c,color:#cce,stroke:#4af
    style PERM  fill:#1a4a2e,color:#cec,stroke:#4f4
    style WEAK  fill:#4a3a00,color:#fec,stroke:#fa0
    style STRONG fill:#4a1a00,color:#fcc,stroke:#f44
    style NET   fill:#3a004a,color:#edf,stroke:#a4f
    style SPEC  fill:#2a2a2a,color:#ccc,stroke:#888
```

> ★pat = explicit patent grant included · ★TiVo = installation-info guard (§6 GPLv3)

---

### 1.2 · Venn: Copyleft Trigger Sets

```mermaid
%%{init: {"theme": "dark", "themeVariables": {
  "background": "#000000",
  "mainBkg": "#000000",
  "nodeBorder": "#555555",
  "clusterBkg": "#111111",
  "clusterBorder": "#444444",
  "titleColor": "#ffffff",
  "edgeLabelBackground": "#000000",
  "fontSize": "13px"
}}}%%
graph TB
    subgraph CORPUS["All 27 Licenses in Corpus"]
        direction LR

        subgraph PERMSET["Set A — Permissive  ·  no copyleft trigger"]
            P1["0BSD  ·  MIT-0  ·  MIT  ·  ISC"]
            P2["BSD-1  ·  BSD-2  ·  BSD-3  ·  Zlib"]
            P3["PostgreSQL  ·  AFL-3.0  ·  Apache-2.0  ·  MS-PL"]
            P4["CC0-1.0  ·  Unlicense"]
        end

        subgraph CLSET["Set B — Copyleft  ·  triggered on distribution"]
            subgraph FILESET["B1 — File / Module scope"]
                D1["MPL-2.0  ·  CDDL-1.0"]
                D2["EPL-2.0  ·  CPL-1.0"]
            end
            subgraph LIBSET["B2 — Library scope"]
                L1["LGPL-2.1  ·  LGPL-3.0"]
            end
            subgraph PROGSET["B3 — Program scope"]
                G1["GPL-2.0  ·  GPL-3.0"]
                G2["EUPL-1.2"]
            end
            subgraph NETSET["B4 ⊂ B3 — Network / SaaS trigger  adds  ∪  distribution"]
                N1["AGPL-3.0"]
                N2["OSL-3.0  (external deployment)"]
            end
        end

        subgraph SPECSET["Set C — Specialized domain  ·  not general software"]
            S1["OFL-1.1  —  Font copyleft"]
            S2["FDL-1.3  —  Document copyleft"]
        end
    end

    style CORPUS   fill:#000,stroke:#333,color:#fff
    style PERMSET  fill:#0d2b0d,stroke:#2a7a2a,color:#a0ffa0
    style CLSET    fill:#1a0808,stroke:#7a2a2a,color:#ffaaaa
    style FILESET  fill:#2a1010,stroke:#aa4444,color:#ffcccc
    style LIBSET   fill:#2a1510,stroke:#aa6644,color:#ffd8cc
    style PROGSET  fill:#2a0808,stroke:#cc3333,color:#ffbbbb
    style NETSET   fill:#200020,stroke:#9933cc,color:#ddb3ff
    style SPECSET  fill:#0d0d2b,stroke:#2a2a7a,color:#aaaaff

    style P1 fill:#0a200a,stroke:#1a5c1a,color:#88ff88
    style P2 fill:#0a200a,stroke:#1a5c1a,color:#88ff88
    style P3 fill:#0a200a,stroke:#1a5c1a,color:#88ff88
    style P4 fill:#0a200a,stroke:#1a5c1a,color:#88ff88
    style D1 fill:#200a0a,stroke:#7a1a1a,color:#ffaaaa
    style D2 fill:#200a0a,stroke:#7a1a1a,color:#ffaaaa
    style L1 fill:#251005,stroke:#8a4a10,color:#ffcc99
    style G1 fill:#250505,stroke:#991010,color:#ff9999
    style G2 fill:#250505,stroke:#991010,color:#ff9999
    style N1 fill:#150020,stroke:#7700cc,color:#cc99ff
    style N2 fill:#150020,stroke:#7700cc,color:#cc99ff
    style S1 fill:#05051a,stroke:#1a1a6a,color:#9999ff
    style S2 fill:#05051a,stroke:#1a1a6a,color:#9999ff
```

---

### 1.3 · Patent Grant Coverage

```mermaid
graph LR
    subgraph NOPAT["No Explicit Patent Grant"]
        NP["MIT · MIT-0 · ISC · 0BSD\nBSD-1/2/3 · Zlib · PostgreSQL\nCC0 · Unlicense · FDL-1.3"]
    end
    subgraph IMPLICIT["Implied / Partial"]
        IM["LGPL-2.1 · GPL-2.0\nCDDL-1.0"]
    end
    subgraph EXPLICIT["Explicit Patent Grant"]
        EX["Apache-2.0 · AFL-3.0\nEPL-2.0 · CPL-1.0 · MPL-2.0\nGPL-3.0 · LGPL-3.0 · AGPL-3.0\nMS-PL · OSL-3.0 · EUPL-1.2\nOFL-1.1"]
    end
    subgraph RETALIATION["+ Patent Retaliation Clause"]
        RT["Apache-2.0 · GPL-3.0 · LGPL-3.0\nAGPL-3.0 · EPL-2.0 · CPL-1.0\nMPL-2.0 · AFL-3.0 · OSL-3.0\nMS-PL · EUPL-1.2"]
    end

    EXPLICIT --> RETALIATION
```

---

## 2 · Full Features Matrix

**Legend:**  ✅ Yes / Explicit   ⚠️ Partial / Conditional   ❌ No   🔒 Copyleft Required   `—` Not Applicable

| License | Category | Copyleft Strength | Copyleft Trigger | Explicit Patent Grant | Patent Retaliation | Attribution Required | Sublicense Allowed | Compatible with Apache-2.0 | Network/SaaS Trigger | Trademark Restriction | Endorsement Prohibition | "Or Later" Version Clause | Warranty Disclaimer | Limitation of Liability | TiVo-ization Guard | Commercial Use | Domain |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **0BSD** | Public Domain-like | None | — | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **MIT-0** | Public Domain-like | None | — | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **Unlicense** | Public Domain | None | — | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **CC0-1.0** | Public Domain | None | — | ⚠️ Waived | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Any |
| **ISC** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **MIT** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **BSD-1-Clause** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **BSD-2-Clause** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **Zlib** | Permissive | None | — | ❌ | ❌ | ⚠️ Binary only | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **PostgreSQL** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **BSD-3-Clause** | Permissive | None | — | ❌ | ❌ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **AFL-3.0** | Permissive + Patent | None | — | ✅ | ✅ | ✅ Attribution | ✅ | ✅ | ⚠️ Ext. Deploy = dist | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **Apache-2.0** | Permissive + Patent | None | — | ✅ | ✅ | ✅ NOTICE file | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **MS-PL** | Permissive + Patent | None | — | ✅ | ✅ | ✅ Notice | ❌ (same-license) | ❌ | ❌ | ✅ (no trademark) | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **OFL-1.1** | Domain-Specific CL | Font copyleft | Distribution | ⚠️ Implied | ❌ | ✅ Notice | ❌ (OFL only) | ⚠️ | ❌ | ✅ Reserved Name | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ (bundled) | Fonts |
| **LGPL-2.1** | Weak Copyleft | Library-level | Distribution of modified lib | ⚠️ Implied | ❌ | ✅ Notice | ✅ | ⚠️ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **LGPL-3.0** | Weak Copyleft | Library-level | Distribution of modified lib | ✅ | ✅ | ✅ Notice | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | Software |
| **MPL-2.0** | Weak / File Copyleft | File-level | Distribution of modified files | ✅ | ✅ | ✅ Notice | ❌ (MPL or compat) | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **CDDL-1.0** | Weak / File Copyleft | File-level | Distribution of modified files | ⚠️ Implied | ❌ | ✅ Notice | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **EPL-2.0** | Weak Copyleft | Module-level | Distribution | ✅ | ✅ | ✅ Notice | ❌ (EPL/GPL option) | ✅ (v2 + GPL compat) | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **CPL-1.0** | Weak Copyleft | Module-level | Distribution | ✅ | ✅ | ✅ Notice | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **FDL-1.3** | Domain-Specific CL | Document copyleft | Distribution | ❌ | ❌ | ✅ (authors, history) | ❌ (FDL only) | — | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | Documentation |
| **GPL-2.0** | Strong Copyleft | Program-level | Distribution | ⚠️ Implied | ❌ | ✅ Notices | ❌ (GPL only) | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **GPL-3.0** | Strong Copyleft | Program-level | Distribution | ✅ | ✅ | ✅ Notices | ❌ (GPL-3 only) | ✅ (Apache-2.0 compat w/GPL-3) | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | Software |
| **OSL-3.0** | Strong Copyleft | Program-level | Dist + Network | ✅ | ✅ | ✅ Attribution | ❌ (OSL only) | ❌ | ✅ External deploy | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | Software |
| **EUPL-1.2** | Strong Copyleft | Program-level | Distribution | ✅ | ✅ | ✅ Notice | ❌ (EUPL + compat list) | ✅ (via compat list) | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Software |
| **AGPL-3.0** | Network Copyleft | Program + Network | Dist + Network interaction | ✅ | ✅ | ✅ Notices | ❌ (AGPL only) | ✅ (Apache-2.0 compat w/AGPL) | ✅ Network interaction | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | Software |

---

## 3 · Feature Deep-Dive

### 3.1 · Copyleft Strength Hierarchy

```mermaid
graph BT
    A["No Copyleft\n(0BSD, MIT, ISC, Apache…)"]
    B["File / Module Copyleft\n(MPL-2.0, CDDL-1.0, EPL-2.0, CPL-1.0)"]
    C["Library Copyleft\n(LGPL-2.1, LGPL-3.0)"]
    D["Program-level Copyleft\n(GPL-2.0, GPL-3.0, OSL-3.0, EUPL-1.2)"]
    E["Network / SaaS Copyleft\n(AGPL-3.0, OSL-3.0*)"]

    A -->|"Stronger →"| B
    B --> C
    C --> D
    D --> E

    style A fill:#2ecc71,color:#000
    style B fill:#f39c12,color:#000
    C fill:#e67e22,color:#000
    style D fill:#e74c3c,color:#fff
    style E fill:#8e44ad,color:#fff
```

*OSL-3.0's "external deployment" clause places it in both D and E.

---

### 3.2 · Compatibility Web (Simplified)

```mermaid
graph LR
    MIT --> Apache2["Apache-2.0"]
    ISC --> Apache2
    BSD3 --> Apache2
    Apache2 -->|"compatible with"| GPL3["GPL-3.0 / AGPL-3.0"]
    MIT --> GPL2["GPL-2.0"]
    LGPL3["LGPL-3.0"] --> GPL3
    EPL2["EPL-2.0"] -->|"v2 GPL compat option"| GPL2
    MPL2["MPL-2.0"] -->|"Secondary License"| GPL3
    EUPL["EUPL-1.2"] -->|"compat list §5"| GPL3

    GPL2 -.-|"INCOMPATIBLE"| Apache2
    CDDL -.-|"INCOMPATIBLE"| GPL2
    CDDL -.-|"INCOMPATIBLE"| GPL3
    MS_PL["MS-PL"] -.-|"INCOMPATIBLE"| GPL2
```

---

## 4 · Detailed Feature Explanations

### 4.1 · Copyleft Trigger Conditions

| Trigger Type | When Activated | Licenses |
|---|---|---|
| **None** | Never | 0BSD, MIT-0, MIT, ISC, BSD-1/2/3, Zlib, PostgreSQL, Apache-2.0, AFL-3.0, MS-PL, CC0, Unlicense |
| **Modified-file distribution** | Only when modified covered files are distributed | MPL-2.0, CDDL-1.0 |
| **Module/program distribution** | Any distribution of the program (binary or source) | EPL-2.0, CPL-1.0, LGPL-2.1, LGPL-3.0, GPL-2.0, GPL-3.0 |
| **External deployment** | Making the work available over a network to third parties | OSL-3.0, AGPL-3.0 |
| **Document distribution** | Distributing modified documentation | FDL-1.3 |
| **Font distribution** | Distributing modified font files | OFL-1.1 |

---

### 4.2 · Patent Grant Matrix

| Feature | Licenses |
|---|---|
| **Full explicit patent grant** | Apache-2.0, AFL-3.0, GPL-3.0, LGPL-3.0, AGPL-3.0, EPL-2.0, CPL-1.0, MPL-2.0, OSL-3.0, MS-PL, EUPL-1.2, OFL-1.1 |
| **Implied / partial (no explicit §)** | GPL-2.0, LGPL-2.1, CDDL-1.0 |
| **No patent grant** | MIT, MIT-0, ISC, 0BSD, BSD-1/2/3, Zlib, PostgreSQL, CC0, Unlicense, FDL-1.3 |
| **Patent retaliation clause** | Apache-2.0, AFL-3.0, GPL-3.0, LGPL-3.0, AGPL-3.0, EPL-2.0, CPL-1.0, MPL-2.0, OSL-3.0, MS-PL, EUPL-1.2 |

---

### 4.3 · Attribution & Notice Requirements

| Requirement Level | Description | Licenses |
|---|---|---|
| **None** | No notices required at all | 0BSD, MIT-0, Unlicense |
| **Copyright notice only** | Retain copyright/license text in copies | ISC, MIT, BSD-1, BSD-2, PostgreSQL, CC0 |
| **Notice + endorsement bar** | Retain notice; prohibit endorsement with author names | BSD-3-Clause, AFL-3.0, Apache-2.0, OSL-3.0 |
| **NOTICE file required** | Must reproduce NOTICE file content | Apache-2.0 |
| **Prominent modification mark** | Must indicate modifications clearly | Zlib, LGPL, GPL, AGPL, MPL, EPL, EUPL |
| **Attribution in source** | Derived source must carry attribution notice | AFL-3.0, OSL-3.0 |
| **Historical record** | Modified docs must record change history | FDL-1.3 |

---

### 4.4 · Sublicensing

| Sublicensing Permitted | Licenses |
|---|---|
| **✅ Yes** | 0BSD, MIT-0, MIT, ISC, BSD-1/2/3, Zlib, PostgreSQL, AFL-3.0, Apache-2.0, CC0, Unlicense, LGPL-2.1, LGPL-3.0 |
| **❌ No (same-license only)** | GPL-2.0, GPL-3.0, AGPL-3.0, MPL-2.0, CDDL-1.0, EPL-2.0, CPL-1.0, OSL-3.0, EUPL-1.2, OFL-1.1, FDL-1.3 |
| **❌ No (same-license, proprietary binary allowed)** | MS-PL |

---

### 4.5 · TiVo-ization / Installation Info Guard

The "TiVo-ization" problem: distributing GPL software in hardware but preventing users from installing modified versions.

| License | Guards Against |
|---|---|
| **GPL-3.0, LGPL-3.0, AGPL-3.0** | ✅ Yes — requires Installation Information for User Products |
| **GPL-2.0, LGPL-2.1** | ❌ No explicit guard |
| **All others** | ❌ Not applicable |

---

## 5 · Selection Criteria Framework

### 5.1 · Decision Tree

```mermaid
flowchart TD
    START["What is the primary goal?"]

    START --> G1["Maximize adoption / integration freedom"]
    START --> G2["Ensure source stays open when distributed"]
    START --> G3["Prevent SaaS loophole (network use = distribution)"]
    START --> G4["Specialized non-software asset"]

    G1 --> PQ1{"Need explicit patent protection?"}
    PQ1 -->|"Yes"| APACHE["→ Apache-2.0"]
    PQ1 -->|"No, minimal friction"| MINIMAL["→ MIT · ISC · BSD-2 · 0BSD"]

    G2 --> CQ1{"How broad should copyleft be?"}
    CQ1 -->|"Only modified files"| FILECL["→ MPL-2.0 (best)\nor CDDL-1.0"]
    CQ1 -->|"Library linking too"| LIBCL["→ LGPL-3.0 (preferred) or LGPL-2.1"]
    CQ1 -->|"Entire program"| PROGCL{"Need patent + TiVo guard?"}
    PROGCL -->|"Yes"| GPL3CL["→ GPL-3.0"]
    PROGCL -->|"No"| GPL2CL["→ GPL-2.0 (legacy compat)"]
    CQ1 -->|"EU-law governed project"| EUPL2["→ EUPL-1.2"]

    G3 --> AGPLCL["→ AGPL-3.0\n(or OSL-3.0 with legal venue caveat)"]

    G4 --> SQ1{"Asset type?"}
    SQ1 -->|"Font"| OFL2["→ OFL-1.1"]
    SQ1 -->|"Documentation"| FDL2["→ FDL-1.3\nor CC0 (truly free)"]
    SQ1 -->|"Any creative work"| CC02["→ CC0-1.0"]
```

---

### 5.2 · Selection Criteria Table

| Criterion | Weight | Favors Permissive | Favors Weak Copyleft | Favors Strong Copyleft | Favors Network Copyleft |
|---|---|---|---|---|---|
| **Maximize downstream adoption** | High | ✅✅ | ✅ | ⚠️ | ❌ |
| **Commercial integration (proprietary use)** | High | ✅✅ | ✅ (file scope) | ❌ | ❌ |
| **Community contribution reciprocity** | High | ❌ | ✅ (scoped) | ✅✅ | ✅✅ |
| **Patent protection (explicit grant)** | Medium | ✅ (Apache, AFL) | ✅✅ | ✅✅ | ✅✅ |
| **SaaS / hosted-service reciprocity** | Medium | ❌ | ❌ | ❌ | ✅✅ |
| **OSI & FSF dual approval** | Medium | ✅✅ | ✅ | ✅✅ | ✅ |
| **Legal clarity / battle-tested** | Medium | ✅✅ | ✅ | ✅✅ | ✅ |
| **Prevent fork-and-close** | Medium | ❌ | ⚠️ (partial) | ✅✅ | ✅✅ |
| **Compatibility with GPL ecosystem** | Medium | ✅ (Apache w/GPL-3) | ✅ (MPL-2.0, EPL-2.0) | ✅ (GPL-3) | ✅ (AGPL) |
| **TiVo / embedded hardware freedom** | Low-Med | ❌ | ❌ | ✅ (GPL-3 only) | ✅ |
| **Minimum attribution burden** | Low | ✅✅ | ✅ | ⚠️ | ⚠️ |
| **Government / EU jurisdiction compat** | Low | ✅ | ✅ | ✅ | ✅ (EUPL-1.2) |

---

### 5.3 · Use-Case Fit Summary

| Use Case | Recommended | Rationale |
|---|---|---|
| Internal tooling, no redistribution | MIT · Apache-2.0 | Minimal friction, clear IP |
| Public library / SDK meant for wide integration | MIT · Apache-2.0 · MPL-2.0 | Permissive or file-scoped copyleft keeps integrators happy |
| Core community project (keep contributions open) | GPL-3.0 · LGPL-3.0 | Strong copyleft ensures reciprocity |
| SaaS / network-deployed service | AGPL-3.0 | Only license that closes network-use loophole |
| Patent-sensitive domain | Apache-2.0 · GPL-3.0 · EPL-2.0 | Explicit grants + retaliation clauses |
| Multi-party standards body | MPL-2.0 · EPL-2.0 | File-scoped copyleft, corporate-friendly |
| Font assets | OFL-1.1 | Domain-specific, widely accepted |
| Documentation / manuals | FDL-1.3 · CC0 | FDL for copyleft docs; CC0 for no restrictions |
| Maximum freedom (no conditions) | 0BSD · Unlicense · CC0 | Closest to public domain |
| Legacy codebase (GPLv2 ecosystem) | GPL-2.0 · LGPL-2.1 | Compatibility with existing GPLv2 code |
| EU-governed project | EUPL-1.2 | Explicit EU jurisdiction, compat list §5 |

---

### 5.4 · Risk Factors by License

| License | Key Risk / Caveat |
|---|---|
| **AGPL-3.0** | Any network-served modified version must release source; strong deterrent to commercial SaaS use |
| **GPL-2.0** | No explicit patent grant; no TiVo guard; incompatible with Apache-2.0 |
| **GPL-3.0** | TiVo guard may conflict with embedded/hardware products |
| **LGPL-2.1** | "Linking" definition ambiguous in dynamic vs static contexts |
| **CDDL-1.0** | GPL-incompatible; file-level scope can be complex to track |
| **CPL-1.0** | Deprecated predecessor to EPL; prefer EPL-2.0 for new projects |
| **OSL-3.0** | Venue clause (licensor's jurisdiction) creates litigation risk; not GPL-compatible |
| **MS-PL** | No sublicensing; compiled derivatives must also use MS-PL–compliant license; unclear on GPL compat |
| **EUPL-1.2** | Complex compatibility list; requires EU legal familiarity |
| **AFL-3.0** | Similar to OSL: attorney-fee clause and venue restriction; same author (Rosen) |
| **FDL-1.3** | Invariant Sections make it incompatible with many uses; Debian "non-free" issues |
| **OFL-1.1** | Fonts only; cannot sell font alone; reserved name constraints |
| **CC0-1.0** | Patent rights not guaranteed waived in all jurisdictions |

---

## 6 · Quick-Reference Cheat Sheet

```
RESTRICTIVE ←————————————————————→ PERMISSIVE

AGPL-3.0  GPL-3.0  GPL-2.0  LGPL-3.0  LGPL-2.1  MPL-2.0  EPL-2.0  Apache-2.0  MIT  0BSD  Unlicense
   |          |        |        |          |          |        |          |        |    |       |
Network     TiVo    Legacy    Library    Library    File     Module    Patent+   Min  None   PD
copyleft    guard   compat    copyleft   copyleft   scope    scope     Notice   attr
```

| Dimension | Minimum | Maximum |
|---|---|---|
| Freedom to use | 0BSD, MIT-0 | AGPL (must release if network-served) |
| Copyleft scope | MIT (none) | AGPL-3.0 (network trigger) |
| Patent protection | MIT (none) | Apache-2.0, GPL-3.0 (explicit + retaliation) |
| Attribution burden | 0BSD (none) | FDL-1.3, AFL-3.0, OSL-3.0 (prominent notices) |
| Commercial friendliness | AGPL (low) | MIT, Apache-2.0 (high) |
| SaaS-service obligation | MIT (none) | AGPL-3.0 (must release source) |

---

*All content derived directly from the license texts in the corpus. Not legal advice.*
