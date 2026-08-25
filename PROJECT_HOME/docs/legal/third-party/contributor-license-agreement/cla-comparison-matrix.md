# CLA Comparison: Features Matrix & Selection Criteria

> **Analysis by:** Claude Sonnet 4.6 (Anthropic) · Generated 2026-08-24

> **Scope:** Six CLA documents found in `third-party/contributor-license-agreement/`
> — analyzed on their own merits, generically, without reference to any specific downstream project.

---

## 0. Visual Overview

### 0a. Document Taxonomy Tree

```mermaid
flowchart TD
    ROOT["CLA Directory<br/>6 Files"]
    ROOT --> LEGAL["Legal Agreement Texts<br/>──────────────────<br/>4 substantive agreements"]
    ROOT --> NONLEGAL["Tooling & Policy<br/>──────────────────<br/>2 non-agreement artifacts"]

    LEGAL --> ICLA_GRP["Individual CLAs"]
    LEGAL --> CCLA_GRP["Corporate CLAs"]

    ICLA_GRP --> AICLA["A-ICLA<br/>apache-icla.pdf<br/>Apache Foundation v2.2"]
    ICLA_GRP --> DICLA["D-ICLA<br/>decathlon-corporate-cla.md<br/>Decathlon / Apache-derived"]
    ICLA_GRP --> OAICLA["OA-ICLA<br/>oasis-individual-cla.md<br/>OASIS Open Projects"]

    CCLA_GRP --> ACCLA["A-CCLA<br/>apache-ccla.pdf<br/>Apache Foundation vr190612"]

    NONLEGAL --> TOOL["GH-CLA<br/>github-cla.md<br/>CLA-assistant tool \(SAP\)"]
    NONLEGAL --> POLICY["GH-OSPO<br/>github-ospo-cla-policy.md<br/>OSPO Governance Template"]

    style LEGAL fill:#1a3a5c,color:#e0f0ff
    style NONLEGAL fill:#3a2a1a,color:#ffe0c0
    style ICLA_GRP fill:#0d2d4a,color:#cce8ff
    style CCLA_GRP fill:#0d2d4a,color:#cce8ff
    style TOOL fill:#2a1a00,color:#ffd080
    style POLICY fill:#2a1a00,color:#ffd080
    style AICLA fill:#003366,color:#aaddff
    style ACCLA fill:#003366,color:#aaddff
    style DICLA fill:#004d33,color:#aaffcc
    style OAICLA fill:#4d0033,color:#ffaacc
```

---

### 0b. Restrictive → Permissive Spectrum

```mermaid
flowchart LR
    A["🔒 MOST RESTRICTIVE<br/>to Contributor"] -.->|increasing contributor freedom| Z["🔓 MOST PERMISSIVE<br/>to Contributor"]

    subgraph P1["Broad irrevocable grant<br/>+ patent + copyright"]
        AICLA["A-ICLA"]
        ACCLA["A-CCLA"]
        DICLA["D-ICLA"]
    end

    subgraph P2["Irrevocable copyright +<br/>NonAssertion patent only"]
        OAICLA["OA-ICLA"]
    end

    subgraph P3["No CLA required<br/>small code exception"]
        DCO["DCO / trivial patch"]
    end

    A --- P1 --- P2 --- P3 --- Z

    style P1 fill:#1a0030,color:#dda0ff
    style P2 fill:#001a30,color:#80c8ff
    style P3 fill:#002a00,color:#80ff80
    style A fill:#4a0000,color:#ff8080
    style Z fill:#004a00,color:#80ff80
```

---

### 0c. Feature Subset Relationships (Set Diagram)

The following Venn captures which agreement feature-sets are subsets of others:

```mermaid
flowchart TD
    subgraph UNIVERSE["Universe of CLA Features"]
        subgraph CR["Copyright Grant \(all 4 ICLAs/CCLAs\)"]
            subgraph PR["+ Patent Grant \(A-ICLA, A-CCLA, D-ICLA\)"]
                subgraph LT["+ Litigation-Termination \(A-ICLA, A-CCLA, D-ICLA\)"]
                    subgraph SA["+ Schedule A Employee List \(A-CCLA only\)"]
                        ACCLA2["A-CCLA"]
                    end
                    AICLA2["A-ICLA"]
                    DICLA2["D-ICLA"]
                end
            end
            subgraph NAC["+ NonAssertion Covenant \(OA-ICLA only\)"]
                OAICLA2["OA-ICLA"]
            end
        end
    end

    style UNIVERSE fill:#0a0a1a,color:#ccccff
    style CR fill:#0a1a2a,color:#aaddff
    style PR fill:#102030,color:#88ccff
    style LT fill:#153040,color:#66bbff
    style SA fill:#1a3a50,color:#44aaff
    style NAC fill:#2a1a00,color:#ffcc44
    style ACCLA2 fill:#003366,color:#ffffff
    style AICLA2 fill:#002244,color:#ffffff
    style DICLA2 fill:#003322,color:#ffffff
    style OAICLA2 fill:#441100,color:#ffffff
```

---

### 0d. Venn — Patent Protection Overlap

```mermaid
flowchart LR
    subgraph IRREV["Irrevocable Patent Grant"]
        AICLA3["A-ICLA"]
        ACCLA3["A-CCLA"]
        DICLA3["D-ICLA"]
    end

    subgraph NONAS["NonAssertion Covenant<br/>\(conditional / withdrawable\)"]
        OAICLA3["OA-ICLA"]
    end

    subgraph LITTERM["Litigation-Termination Clause"]
        AICLA3
        ACCLA3
        DICLA3
    end

    style IRREV fill:#1a0040,color:#cc88ff
    style NONAS fill:#401a00,color:#ffaa44
    style LITTERM fill:#001a40,color:#4488ff
```

---

### 0e. Venn — Entity / Scope Coverage

```mermaid
flowchart TD
    subgraph ALL["All 4 legal agreements"]
        subgraph IND["Covers Individual Contributors"]
            AICLA4["A-ICLA"]
            DICLA4["D-ICLA"]
            OAICLA4["OA-ICLA"]
            subgraph CORP["Also covers Corporate/Entity"]
                ACCLA4["A-CCLA<br/>\(employee roster via Sched A\)"]
            end
        end
        subgraph DUAL["Requires BOTH ICLA + Entity CLA"]
            OAICLA4
        end
        subgraph BULK["Bulk Software Grant \(Schedule B\)"]
            ACCLA4
        end
    end

    style ALL fill:#0a0a0a,color:#cccccc
    style IND fill:#001a30,color:#aaddff
    style CORP fill:#002244,color:#88ccff
    style DUAL fill:#1a0030,color:#cc88ff
    style BULK fill:#003300,color:#88ff88
    style AICLA4 fill:#004488,color:#ffffff
    style DICLA4 fill:#004422,color:#ffffff
    style OAICLA4 fill:#440044,color:#ffffff
    style ACCLA4 fill:#006600,color:#ffffff
```

---

## 1. Documents Analyzed

| ID | File | Organization | Type | Format |
|----|------|-------------|------|--------|
| **A-ICLA** | `apache-icla.pdf` | Apache Software Foundation | Individual CLA | PDF (v2.2) |
| **A-CCLA** | `apache-ccla.pdf` | Apache Software Foundation | Corporate/Software-Grant CLA | PDF (vr190612) |
| **D-ICLA** | `decathlon-corporate-cla.md` | Decathlon (Apache-derived) | Individual CLA | Markdown |
| **GH-CLA** | `github-cla.md` | SAP / cla-assistant.io | CLA *Automation Tool* (not a CLA text) | Markdown |
| **GH-OSPO** | `github-ospo-cla-policy.md` | Generic OSPO template | CLA Policy / Governance Document | Markdown |
| **OA-ICLA** | `oasis-individual-cla.md` | OASIS Open Projects | Individual CLA | Markdown (web-form exhibit) |

> [!NOTE]
> `github-cla.md` is the README for the **CLA-assistant** open-source tool (by SAP, Apache-2.0 licensed).
> It describes *automation infrastructure* for enforcing any CLA, not a CLA text itself.
> `github-ospo-cla-policy.md` is a templated OSPO *policy document* for employee guidance — again not a CLA text.
> Both are evaluated as **tooling/policy** artifacts, not as legal agreements.

---

## 2. Legal Agreement Features Matrix

### 2a. Core Grant Clauses

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Copyright license grant** | ✅ Perpetual, worldwide, non-exclusive, royalty-free, irrevocable | ✅ Identical to A-ICLA | ✅ Identical to A-ICLA | ✅ Perpetual, worldwide, non-exclusive, royalty-free, irrevocable + sublicense right |
| **Derivative works right** | ✅ Prepare & distribute | ✅ Prepare & distribute | ✅ Prepare & distribute | ✅ Prepare, publicly display, perform & distribute |
| **Patent license grant** | ✅ Perpetual, worldwide, non-exclusive, royalty-free, irrevocable (with litigation termination) | ✅ Identical to A-ICLA | ✅ Identical to A-ICLA | ✅ Via "Specification NonAssertion Covenant" (more conditional, standards-body model) |
| **Patent litigation termination clause** | ✅ Terminates on filing date | ✅ Terminates on filing date | ✅ Terminates on filing date | ⚠️ Via NonAssertion Covenant (terminable under different conditions) |
| **Software grant (bulk pre-contribution)** | ❌ Not included | ✅ Schedule B for concurrent bulk grants | ❌ Not included | ❌ Not included |
| **Sublicense right granted** | ✅ Implied (distribute to recipients) | ✅ Implied | ✅ Implied | ✅ Explicit direct+indirect sublicense |
| **License scope** | Contributions to Foundation works | Contributions to Foundation works + Schedule B grant | Contributions to Decathlon works | Contributions to any OASIS Open Project repo |
| **License target** | Foundation + downstream recipients | Foundation + downstream recipients | Decathlon + downstream recipients | OASIS + downstream via Applicable License |

---

### 2b. Contributor Entity Type & Control

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Contributor type** | Individual (natural person or authorized legal entity) | Corporation / Organization | Individual | Individual (Entity CLA required separately for corps) |
| **"Control" definition (50% rule)** | ✅ Defined (power, shares, beneficial ownership) | ✅ Identical | ✅ Identical | ❌ Not explicitly defined |
| **Employer-rights representation** | ✅ §4: Requires employer permission/waiver or Corporate CLA | ✅ §4: Corp authorizes named employees via Schedule A | ✅ §4: Same as Apache ICLA | ✅ Contributor represents they have employer permission |
| **Employee designation mechanism** | ❌ N/A (individual) | ✅ Schedule A (list of authorized employees, mutable) | ❌ N/A (individual) | ❌ N/A (Entity CLA separate) |
| **Third-party submission mechanism** | ✅ §7: Mark as "Submitted on behalf of third-party" | ✅ §7: Same mechanism | ⚠️ §7 replaced with a prohibition on copying incompatible-licensed code | ❌ Not included |

---

### 2c. Contributor Representations & Warranties

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Original creation representation** | ✅ §5 | ✅ §5 | ✅ §5 | ✅ Implicit |
| **Third-party restriction disclosure** | ✅ §5 (patents, trademarks, licenses) | ✅ §5 | ✅ §5 | ✅ Required |
| **"AS IS" no-warranty disclaimer** | ✅ §6 | ✅ §6 | ✅ §6 | ❌ Not stated |
| **Notification of inaccuracies obligation** | ✅ §8 | ✅ §8 | ✅ §8 | ✅ Notification to OASIS required |
| **License compatibility obligation** | ❌ Not mentioned | ❌ Not mentioned | ✅ §7: Explicit — prohibits copying code under incompatible licenses | ❌ Not mentioned |
| **Ownership/rights reserved** | ✅ Contributor retains all rights outside scope | ✅ Contributor retains all rights outside scope | ✅ Contributor retains all rights outside scope | ✅ Not a transfer of ownership |

---

### 2d. Scope & Applicability

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Temporal scope** | Present + future contributions | Present + future contributions | Present + future contributions | Present + future (all repos of that OASIS project) |
| **Contribution definition breadth** | Original work + modifications + additions; excludes "Not a Contribution" marked comms | Same; adds Schedule B explicit works | Same as Apache; excludes marked comms | Original work + modifications + additions submitted to any OASIS Open Project repo |
| **Submitted channels** | Email, mailing lists, SCM, issue trackers | Same + explicit bulk via Schedule B | Same | Same (any submission to OASIS project repos) |
| **Project specificity** | Any Foundation-managed product | Any Foundation-managed product + Schedule B named works | Any Decathlon OSS product | Any OASIS Open Project (cross-project scope) |
| **Dual Individual+Corporate model** | ❌ Separate docs required | ✅ Corporate model is this doc | ✅ References separate Corporate CLA | ✅ Explicit: ICLA + Entity CLA both required |

---

### 2e. Process & Mechanics

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Execution mechanism** | Wet signature → PDF via email | Wet/digital signature → PDF via email | Wet signature → scan/PDF via email | Online web form + email confirmation |
| **Storage / record** | Apache Foundation file | Apache Foundation file | Decathlon file | OASIS permanent public record |
| **Contributor data collected** | Name (public/private), address, country, email, optional Apache ID, notify project | Corp name, address, POC, email, phone + Schedule A employees | Full name, postal address, email, GitHub handle, date, signature | Name, email, GitHub username, mailing address, employer info |
| **Identity verification** | None beyond signature attestation | None beyond signature attestation | None beyond signature attestation | Email reply confirmation |
| **Automation support** | ❌ Manual process | ❌ Manual process | ❌ Manual process | ❌ Manual web form + email |
| **Versioning** | v2.2 (publicly versioned) | vr190612 (date-versioned) | "Adapted from Apache" (no version) | Referenced to Open Project Rules (externally versioned) |
| **CLA re-sign on update** | ❌ Not addressed | ❌ Not addressed | ❌ Not addressed | ❌ Not addressed in text |
| **Privacy policy reference** | ✅ s.apache.org/cla-privacy-policy | ❌ Not referenced | ❌ Not referenced | ✅ Public record explicitly noted |

---

### 2f. Nonprofit / Public Benefit Constraint on Licensor

| Feature | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---------|--------|--------|--------|---------|
| **Licensor constrained to public benefit** | ✅ "shall not use in a way contrary to public benefit or inconsistent with its nonprofit status" | ✅ Same | ✅ Same (adapted) | ❌ No such constraint |
| **Nonprofit bylaws alignment required** | ✅ Explicitly | ✅ Explicitly | ✅ Adapted reference | ❌ Not stated |

---

## 3. Tooling & Policy Document Analysis

### 3a. GitHub CLA-Assistant (`github-cla.md`)

This is the README of the **cla-assistant** open-source project by SAP (Apache-2.0).

| Capability | Detail |
|-----------|--------|
| **What it is** | A GitHub-integrated web service + GitHub Action that automates CLA collection during PR workflow |
| **CLA storage model** | CLA text stored as a GitHub Gist; signee data stored in Cosmos DB (Azure, EU region) |
| **Signing flow** | PR opened → bot comments → contributor signs in-PR via GitHub OAuth |
| **Authentication** | GitHub account OAuth |
| **Re-sign on CLA update** | ✅ Automatic re-sign request when Gist changes |
| **Custom fields** | ✅ JSON metadata schema drives dynamic form generation |
| **Bot/automation allowlisting** | ✅ Bot users (Dependabot, etc.) can be whitelisted |
| **Export** | ✅ CSV export of signee list |
| **Self-hosting** | ✅ Full self-host via Docker Compose or manual Node.js |
| **Hosted SaaS** | ✅ cla-assistant.io (free, SAP-operated) |
| **GHE support** | ✅ Configurable `GITHUB_HOST` / `GITHUB_API_HOST` env vars |
| **Data residency** | Azure Cosmos DB, Europe |
| **Lite variant** | ✅ GitHub Actions-only version available |

### 3b. GitHub OSPO CLA Policy (`github-ospo-cla-policy.md`)

A **templated internal governance document** (placeholders: `<COMPANY_NAME>`, `<LEGAL_CONTACT>`).

| Aspect | Content |
|--------|---------|
| **Purpose** | Explains CLA concepts to employees and sets organizational policy |
| **ICLA guidance** | Employees sign in personal capacity; OSPO/Legal review required; Section 4 Apache language sufficient for employer-permission representation |
| **CCLA stance** | ❌ OSPO/Legal **discourages CCLAs**; prefers ICLA; if CCLA done, contributor maintains it themselves |
| **Small code exception** | ✅ Bug fixes / trivial patches exempt from CLA requirement |
| **Own repos policy** | ❌ Explicitly **does not use CLAs** on own repos (cites Ben Balter rationale) |
| **Use case** | Guidance for employees contributing *to external projects that require CLAs* |

---

## 4. Comparative Dimensions Summary

### 4a. Legal Strength / Protection Spectrum

```
Strongest corporate protection ←————————————————————→ Lightest touch

  A-CCLA          A-ICLA / D-ICLA        OA-ICLA          (no CLA)
  (corp +         (individual,           (individual,     (DCO/license
  Schedule A +    nonprofit              standards-body    headers only)
  bulk grant)     constraint)            NonAssertion)
```

### 4b. Patent Treatment Comparison

| | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---|---|---|---|---|
| **Patent grant** | Broad, irrevocable | Broad, irrevocable | Broad, irrevocable | NonAssertion Covenant only (conditional, reversible) |
| **Termination trigger** | Patent litigation filed | Patent litigation filed | Patent litigation filed | Withdrawal under covenant terms |
| **Scope** | Claims necessarily infringed by contribution alone or in combination | Same | Same | Claims described in covenant; varies by PGB membership |

> [!WARNING]
> OASIS's NonAssertion Covenant model is significantly weaker as patent protection than the Apache-style irrevocable patent grant.
> It is designed for standards bodies (OASIS), not typical OSS projects.

### 4c. Third-Party / Non-Original Code

| | A-ICLA | A-CCLA | D-ICLA | OA-ICLA |
|---|---|---|---|---|
| **Mechanism** | §7 "on behalf of third-party" carve-out | §7 Same | Prohibition — do not submit incompatible code | No explicit mechanism |

> [!NOTE]
> Decathlon replaces the Apache §7 pass-through mechanism with a **prohibition on submitting code under incompatible licenses**.
> This is stricter but trades flexibility for clarity.

---

## 5. Selection Criteria Framework

When evaluating which CLA type or combination best fits a use case, apply the following criteria:

### 5.1 Contributor Profile

| Criterion | Prefer |
|-----------|--------|
| Only individual contributors | **A-ICLA** or **D-ICLA** or **OA-ICLA** |
| Mix of individual + corporate contributors | **A-ICLA** + **A-CCLA** pair |
| Primarily corporate contributors with employee pools | **A-CCLA** (Schedule A employee management) |
| Standards-body contributors | **OA-ICLA** + OASIS Entity CLA |
| Minimize friction for small/trivial contributions | OSPO small-code exception (no CLA) or DCO only |

### 5.2 Patent Protection Priority

| Criterion | Prefer |
|-----------|--------|
| Maximum irrevocable patent protection | **A-ICLA** / **A-CCLA** (explicit irrevocable grant) |
| Standards-oriented patent framework | **OA-ICLA** (NonAssertion Covenant) |
| Basic patent protection, minimal complexity | **D-ICLA** (Apache-derived, sufficient for OSS) |
| No patent concerns / pure copyright | DCO or MIT-style headers alone |

### 5.3 Organizational Lineage & Ecosystem Fit

| Criterion | Prefer |
|-----------|--------|
| Established ASF-ecosystem projects | **A-ICLA** + **A-CCLA** (widely recognized, legally vetted) |
| Standards/specification work | **OA-ICLA** + OASIS Entity CLA |
| Retail/commercial company OSS projects | **D-ICLA** (Decathlon model) or **A-ICLA** derivative |
| Projects hosted on GitHub | **A-ICLA** text + **CLA-assistant** tooling |
| Enterprise with OSPO governance | **GH-OSPO** policy + ICLA per contributor |

### 5.4 Process Overhead vs. Legal Rigor

| Priority | Tradeoff | Recommended |
|----------|----------|-------------|
| Maximum legal rigor | High friction (PDF, email, manual file) | **A-ICLA** + **A-CCLA** |
| Moderate rigor, digital workflow | Medium friction | **OA-ICLA** (web form + email confirm) |
| Low friction, automated GitHub PR flow | Relies on tooling | Any CLA text + **CLA-assistant** |
| Minimal burden, community-friendly | Lowest rigor | DCO (`git commit -s`) only |
| Corporate OSPO risk management | Balanced | **GH-OSPO** policy + ICLA review gate |

### 5.5 Data Privacy & Residency

| Criterion | Prefer |
|-----------|--------|
| Contributor PII under own control | Self-hosted CLA-assistant or manual file |
| EU data residency (hosted) | CLA-assistant.io (Azure EU) |
| Minimal PII collection | DCO (no form, just commit email) |
| Explicit privacy policy reference | **A-ICLA** (references Apache privacy policy) |

### 5.6 Licensor Constraint (Public Benefit Alignment)

| Criterion | Prefer |
|-----------|--------|
| Nonprofit project, wants contributor assurance | **A-ICLA** / **A-CCLA** / **D-ICLA** (nonprofit-use constraint on licensor) |
| Commercial project, no such constraint desired | **OA-ICLA** or custom (no nonprofit clause) |
| Policy/internal guidance only | **GH-OSPO** template |

### 5.7 Re-licensing Flexibility

| Criterion | Prefer |
|-----------|--------|
| Potential future license change | **A-ICLA** / **A-CCLA** (broad irrevocable grant, sublicense rights) |
| Fixed to specific Applicable License | **OA-ICLA** (tied to repo's designated license) |
| Dual-licensing or commercial relicensing | **A-ICLA** / **A-CCLA** (grant structure supports it) |

---

## 6. CLA Type Taxonomy

```
CLA Documents in Collection
├── Legal Agreement Texts (substantive legal docs)
│   ├── Individual CLAs (ICLAs)
│   │   ├── Apache ICLA (A-ICLA) — canonical, industry standard
│   │   ├── Decathlon ICLA (D-ICLA) — Apache-derived, stricter §7
│   │   └── OASIS Individual CLA (OA-ICLA) — standards-body model
│   └── Corporate CLAs (CCLAs)
│       └── Apache CCLA (A-CCLA) — corp + Schedule A + bulk grant
│
└── Tooling & Policy (non-agreement artifacts)
    ├── CLA-assistant README (GH-CLA) — automation tool (SAP/GitHub)
    └── OSPO CLA Policy Template (GH-OSPO) — internal governance
```

### Mermaid: Feature Inclusion Tree (Subset Hierarchy)

Each inner ring is a **strict subset** of the outer ring — the outermost ring describes the broadest agreement class, inward layers add features only some CLAs possess.

```mermaid
flowchart TD
    F0["ALL CLAs: Copyright License Grant<br/>perpetual · worldwide · non-exclusive · royalty-free"]
    F0 --> F1["+ Derivative Works Rights<br/>A-ICLA · A-CCLA · D-ICLA · OA-ICLA"]
    F1 --> F2["+ Irrevocable Patent Grant<br/>A-ICLA · A-CCLA · D-ICLA"]
    F2 --> F3["+ Patent Litigation Termination<br/>A-ICLA · A-CCLA · D-ICLA"]
    F3 --> F4a["+ Schedule A Employee Roster<br/>A-CCLA only"]
    F3 --> F4b["+ Schedule B Bulk Software Grant<br/>A-CCLA only"]
    F3 --> F4c["+ §7 Third-Party Pass-Through<br/>A-ICLA · A-CCLA"]
    F3 --> F4d["+ License Compatibility Prohibition<br/>D-ICLA only"]
    F1 --> F2b["+ NonAssertion Covenant \(not irrevocable grant\)<br/>OA-ICLA only"]
    F0 --> FNP["+ Nonprofit-Use Constraint on Licensor<br/>A-ICLA · A-CCLA · D-ICLA"]

    style F0 fill:#0a0a2a,color:#aaaaff
    style F1 fill:#0a1a2a,color:#88ccff
    style F2 fill:#0a2a1a,color:#88ffaa
    style F3 fill:#1a2a0a,color:#ccff88
    style F4a fill:#2a1a00,color:#ffcc44
    style F4b fill:#2a1a00,color:#ffcc44
    style F4c fill:#2a1a00,color:#ffcc44
    style F4d fill:#2a0a0a,color:#ff8888
    style F2b fill:#2a0a2a,color:#ff88ff
    style FNP fill:#1a0a2a,color:#cc88ff
```

### Mermaid: Permissive ↔ Restrictive Axis — Two Dimensions

```mermaid
quadrantChart
    title CLA Restrictiveness: Contributor Burden vs. Licensor Grant Breadth
    x-axis "Low Contributor Burden" --> "High Contributor Burden"
    y-axis "Narrow Licensor Grant" --> "Broad Licensor Grant"
    quadrant-1 "Broad grant, high burden"
    quadrant-2 "Narrow grant, high burden"
    quadrant-3 "Narrow grant, low burden"
    quadrant-4 "Broad grant, low burden"
    A-ICLA: [0.65, 0.88]
    A-CCLA: [0.80, 0.92]
    D-ICLA: [0.70, 0.82]
    OA-ICLA: [0.50, 0.60]
    DCO-only: [0.10, 0.20]
    No-CLA: [0.05, 0.05]
```

---

## 7. Key Differentiators at a Glance

| Differentiator | Winner | Notes |
|---------------|--------|-------|
| **Broadest patent protection** | A-ICLA / A-CCLA | Irrevocable, explicit, litigation-termination |
| **Standards-body compliance** | OA-ICLA | NonAssertion Covenant required for OASIS |
| **Corporate employee management** | A-CCLA | Schedule A mutable list |
| **Bulk software grant** | A-CCLA | Schedule B |
| **Strictest compatibility gate** | D-ICLA | §7 prohibition on incompatible code |
| **Best automation / UX** | GH-CLA (cla-assistant tool) | PR-integrated, OAuth, auto re-sign |
| **Lowest contributor friction** | GH-OSPO small-code exception / DCO | No CLA required for trivial patches |
| **Most widely recognized / portable** | A-ICLA | Industry default; used by Linux Foundation derivatives |
| **Nonprofit-use constraint on licensor** | A-ICLA / A-CCLA / D-ICLA | Contributor assurance against misuse |
| **Explicit privacy policy** | A-ICLA | References apache.org privacy policy |
| **Online digital signing** | OA-ICLA | Web form; GH CLA-assistant automates any text |

---

## 8. Selection Decision Tree

```mermaid
flowchart TD
    START(["Start: Choose a CLA approach"])

    START --> Q1{"Are contributions from<br/>corporations / employers?"}

    Q1 -->|"Yes — corporate entity contributors"| Q2{"Need bulk pre-existing<br/>software grant \(Schedule B\)?"}
    Q2 -->|"Yes"| ACCLA_REC["► A-CCLA\n+ Schedule B bulk grant\n+ Schedule A employee roster"]
    Q2 -->|"No"| Q3{"Standards body / OASIS project?"}
    Q3 -->|"Yes"| OAICLA_REC["► OA-ICLA + OASIS Entity CLA"]
    Q3 -->|"No"| PAIR_REC["► A-ICLA \(employees in personal cap\)\n+ A-CCLA \(corp entity\)"]

    Q1 -->|"No — individual contributors only"| Q4{"Standards body / specification work?"}
    Q4 -->|"Yes"| OAICLA2_REC["► OA-ICLA"]
    Q4 -->|"No"| Q5{"Is maximum irrevocable<br/>patent protection required?"}
    Q5 -->|"Yes"| Q6{"Strict incoming license<br/>compatibility gate needed?"}
    Q6 -->|"Yes"| DICLA_REC["► D-ICLA\n\(Apache-derived + compatibility prohibition §7\)"]
    Q6 -->|"No"| AICLA_REC["► A-ICLA\n\(canonical, §7 third-party pass-through\)"]
    Q5 -->|"No — minimal friction preferred"| Q7{"Contribution is trivial<br/>\(bug fix, typo\)?"}
    Q7 -->|"Yes"| DCO_REC["► No CLA — DCO or small-code exception"]
    Q7 -->|"No"| AICLA2_REC["► A-ICLA\n\(lightest full-protection individual CLA\)"]

    ACCLA_REC --> AUT{"Want automated PR enforcement?"}
    AICLA_REC --> AUT
    DICLA_REC --> AUT
    PAIR_REC --> AUT
    AUT -->|"Yes"| TOOL_REC["Layer on: CLA-assistant\n\(github-cla.md tooling\)"]
    AUT -->|"No"| MANUAL_REC["Manual: PDF email + file"]

    style START fill:#1a1a3a,color:#aaaaff
    style ACCLA_REC fill:#003366,color:#aaddff
    style AICLA_REC fill:#003366,color:#aaddff
    style AICLA2_REC fill:#003366,color:#aaddff
    style DICLA_REC fill:#003322,color:#aaffcc
    style OAICLA_REC fill:#330033,color:#ffaaff
    style OAICLA2_REC fill:#330033,color:#ffaaff
    style PAIR_REC fill:#003355,color:#aaccff
    style DCO_REC fill:#003300,color:#aaffaa
    style TOOL_REC fill:#331a00,color:#ffcc88
    style MANUAL_REC fill:#1a1a1a,color:#cccccc
```

---

*Analysis based on the six documents in `third-party/contributor-license-agreement/` as found on disk. No external sources were consulted.*
