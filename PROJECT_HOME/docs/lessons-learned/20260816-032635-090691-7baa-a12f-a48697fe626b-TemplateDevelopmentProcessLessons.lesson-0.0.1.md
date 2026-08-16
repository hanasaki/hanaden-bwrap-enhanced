---
lesson-id:    20260816-032635-090691-7baa-a12f-a48697fe626b-TemplateDevelopmentProcessLessons
pk:           0199b095-6452-7baa-a12f-a48697fe626b
recorded:     2026-08-16T03:26:35Z
author:       Frederick Bloom (with Antigravity AI assistance)
author-type:  HUMAN_AI_COLLABORATIVE
aspect:       PROCESS-CHANGE
domain:       PROCESS
category:     PROCESS
recurrence:   0
files_changed: 2
severity:     MINOR
status:       RESOLVED
supersedes:   null
related:      null
tags:         [template-development, process, architecture, lessons-learned]
compiling-agent-harness: Antigravity IDE v1.1.10 (Google DeepMind)
compiling-llm-engine:    Gemini 2.5 Pro
audited-subject-ai:      Antigravity AI (template authoring session)
---

<!-- (c) 2026-* Frederick Bloom -- 20260816-032635-090691-7baa-a12f-a48697fe626b-TemplateDevelopmentProcessLessons.lesson-0.0.1.md -- Hanaden AI Loader -->

# Template development requires real-doc analysis before any writing

> [!IMPORTANT]
> **AI REPORT PROVENANCE & AUTHORSHIP DISCLOSURE**
> This report was compiled by a Human+AI collaborative session.
> - **Audited Subject AI:** `Antigravity AI — session 9ddb73b1-d606-42f1-8549-a66eb7c39d33`
> - **Compiling Agent Harness:** `Antigravity IDE v1.1.10 (Google DeepMind)`
> - **Compiling LLM Engine:** `Gemini 2.5 Pro`
> - **Report Generation Timestamp:** `2026-08-16T03:26:35Z`

## Lessons Learned

- **Read every real doc before writing the template.** The first template draft was built without reading the existing files and required 10+ corrective iterations.
- **Fetch all standards URLs live before writing; document what is inaccessible.** `cve.org` and `llis.nasa.gov` are JS SPAs — unfetchable. Training data is not a substitute.
- **Run the transformation test before declaring the template complete.** "Can every existing file be represented in this template?" surfaces gaps that inspection misses.
- **Apply DRY aggressively — the template is not a textbook.** The draft grew to 1,413 lines; the final is 783 lines. Everything cut had a real reason.
- **The frontmatter schema must be a superset of all real files, not just the design doc.** The design doc schema and actual file frontmatter diverge materially.
- **Run a structured per-standard gap audit at the end, field by field.** A spot check missed the CVE `last modified` field; the structured audit caught it.

## Abstract

During a multi-turn session, a Hanaden Lessons Learned universal template was designed and refined iteratively. The initial approach — writing the template before reading real documents — produced a 1,413-line bloated artifact with missing required fields and incorrect optional coverage. Subsequent analysis of all 31 real lesson files in `docs/lessons-learned/` revealed material divergence between the authoritative design doc schema and actual file frontmatter, including fields absent from the design doc (`pk`, AI provenance trio) and fields in the design doc absent from all real files (`recurrence`, `files_changed`). Standards were verified by live URL fetching: IMRAD via Wikipedia, CVSS via FIRST.org, and CWE via MITRE — confirming three metric groups for CVSS and live field names for CWE entries. Two target URLs (`cve.org`, `llis.nasa.gov`) were JavaScript SPAs returning no static content, requiring fallback to NVD JSON schema and the project design doc respectively; this was documented in an Appendix D anti-fabrication audit rather than silently substituted. A structured field-by-field gap audit identified one missed field (CVE last modified date), which was immediately remediated. The final template at 783 lines covers all 13/13 verifiable IMRAD requirements, 6/6 known NASA ADLR fields, 10/17 CWE fields (6 omitted by DRY with rationale), 10/10 CVE/NVD fields, and 20/20 CVSS v3.1 metrics.

## Introduction

The Hanaden project maintains a `docs/lessons-learned/` corpus of structured lesson files, governed by `hanaden-lessons-learned.design-0.0.2.md`. A universal template was needed to standardize authoring across all lesson types and ensure consistent transformation from real files to the canonical schema. The session objective was to produce a single template file that (a) could represent all existing lesson files without data loss, (b) mapped completely to IMRAD and NASA ADLR standards, (c) provided correct CVSS/CWE/CVE documentation for security lessons, and (d) was lean enough for practical use.

### Context

- **Project:** Hanaden bwrap-enhanced
- **Phase:** Documentation infrastructure — template authorship
- **Domain:** `PROCESS`
- **Trigger:** Absence of a universal template caused lesson files to diverge structurally across three generations (early-era DSL-only, transitional IMRAD, full IMRAD)
- **Prior state:** No template existed; 31 real lesson files spanning three structural generations with no common schema enforcement
- **New state:** Single `LessonsLearnedUniversalTmpl.tmpl-0.0.1.md` covering all structural variants as a superset, with 4 appendices (Mermaid guide, Security Extension, UUIDv7 spec, Standards Audit)

## Methods

The session proceeded in five phases: (1) **Initial draft** — template written from design doc and IMRAD framework knowledge before reading real files; (2) **Real-file audit** — all 31 lesson files read and analyzed for structural generation, frontmatter field coverage, and policy compliance; (3) **Gap identification** — diff between design doc schema, actual file frontmatter, and template draft; (4) **Live standards verification** — URL fetches to FIRST.org, Wikipedia, MITRE CWE, and NVD to confirm field enumerations; (5) **Structured audit** — field-by-field checklist against each standard, remediating gaps found.

The transformation test was applied: for each of the five structural generations of real lesson files, every body section and frontmatter field was tested for whether it could be mapped to a template slot. This test revealed which data would be lost (e.g., `## Driving Event` in early-era files has no template slot) vs. which could be remapped (e.g., `reporter-type` → `author-type`).

### Confirmation Test

The transformation test was applied systematically. For the Full IMRAD generation (11 files), all 12 body sections mapped directly except `## Lessons Learned` (front-loaded), which was absent from source files — confirming this section required fresh authoring, not transformation, for that generation. This isolated the gap to authoring effort rather than a structural incompatibility.

## Results

| Phase | Outcome | Measurable result |
|---|---|---|
| Initial draft (no prior reading) | Bloated, missing fields | 1,413 lines; `pk` absent; `recurrence`/`files_changed` absent |
| After real-file audit | Fields added, DRY applied | 780 lines; `pk`, AI provenance, `recurrence`, `files_changed` added |
| After live standards fetch | CVSS completed; CWE fields sourced | All 3 CVSS metric groups documented; CWE fields from live v4.20 HTML |
| After structured audit | One gap found and fixed | CVE `last modified` added; 10/10 CVE fields |
| Final state | 10+ corrective iterations total | 783 lines; 0 actionable gaps |

Inaccessible live sources: `cve.org` (Vue.js SPA), `llis.nasa.gov` (Ember SPA), Semantic Scholar paper (HTTP 202). All documented in Appendix D rather than substituted with training data.

Three universal frontmatter failures across all 31 real files: `author`, `recurrence`, `files_changed` — none present in any source file. Cannot be filled from existing data without live `git diff --stat` queries and lesson history searches.

## Discussion

**Comparison to prior work:** The design doc (`hanaden-lessons-learned.design-0.0.2.md`) specifies a complete RDBMS schema; however, the actual lesson files implement only a subset, with some RDBMS fields absent from all 31 records and some file fields absent from the RDBMS schema. Writing the template from the design doc alone — without reading real files — produces a spec-compliant template that cannot represent the actual corpus. Both sources are required.

**Limitations of this analysis:** The Semantic Scholar IMRAD paper (`be2ef84f...`) was inaccessible via static fetch (HTTP 202 content negotiation). The NASA ADLR full field set was not independently verifiable because `llis.nasa.gov` returns no static content. The ADLR coverage is sourced from the project design doc, which may itself be incomplete. `cve.org` is a Vue.js SPA; CVE coverage is sourced from the NVD JSON 2.0 schema as a proxy.

**Practical implications:** Any template-authoring task in this project requires a mandatory pre-authoring phase: (1) read the authoritative design doc; (2) read every real file in the target directory; (3) diff the two for divergence; (4) only then write. Writing before reading produces a template that passes visual inspection but fails the transformation test.

## Conclusions

A template written before reading real docs will require 10+ corrective iterations regardless of how well the author knows the governing standard. The design doc and real file corpus diverge materially; both are required inputs. Live URL verification is essential and must distinguish between accessible and inaccessible sources — the latter documented rather than silently substituted. The transformation test ("can every existing file be represented?") is more discriminating than direct inspection and should be run before declaring any template complete. A structured per-standard field audit catches gaps that inspection misses.

- Standards coverage is only verifiable for sources that return static content
- `cve.org` and `llis.nasa.gov` are JavaScript SPAs — plan alternative sources before starting
- The template-as-textbook antipattern (1,413 lines) is detectable early by checking line count against the target files' average size

## Lesson Learned

A template for structured documents must be derived from two co-equal sources: the authoritative design specification AND the actual existing files in the target corpus. Either source alone is insufficient. The design spec describes the intended schema; real files reveal the implemented schema and the organic extensions that accumulated outside the spec. A template that covers only the spec will fail the transformation test. A template that covers only the real files will miss spec-required fields that no file has yet implemented.

- The design doc schema and real file frontmatter diverged on 10+ fields in this session
- Real files had fields absent from the design doc (`compiling-agent-harness`, `updated`)
- The design doc had required fields absent from all 31 real files (`recurrence`, `files_changed`)
- Both sources must be read before writing begins

## Recommendation

Before authoring any template for a structured document corpus in the Hanaden project:

- (Immediate) **Read the governing design doc first.** Identify all REQUIRED, OPTIONAL, and DERIVED fields, the controlled vocabularies, and the mandatory section order.
- (Immediate) **Read every real file in the target directory.** For each file, record: frontmatter fields present, body section headings in order, and any structural variant from the design doc.
- (Immediate) **Diff the two sources before writing.** Produce an explicit list of: fields in spec but not files; fields in files but not spec; section names that differ from spec.
- (Long-term) **Run the transformation test before declaring the template done.** For each structural generation of real files, verify every section and field maps to a template slot without data loss.
- (Long-term) **Run a structured per-standard field audit.** For each referenced standard (IMRAD, CVSS, CWE, CVE, NASA ADLR), verify coverage field by field. Document inaccessible live sources explicitly in an appendix — never substitute training data.

## References

- Session: `9ddb73b1-d606-42f1-8549-a66eb7c39d33`
- Template produced: `docs/doc-templates/20260816-023041-926274-7091-a7d3-ca9740cb3d9a-LessonsLearnedUniversalTmpl.tmpl-0.0.1.md`
- Design doc: `docs/lessons-learned/hanaden-lessons-learned.design-0.0.2.md`
- Real files audited: 31 files in `docs/lessons-learned/`
- **Standards:**
  - [IMRAD](https://en.wikipedia.org/wiki/IMRAD)
  - [NASA ADLR](https://llis.nasa.gov/)
  - [CWE](https://cwe.mitre.org/)
  - [CVE / NVD](https://nvd.nist.gov/)
  - [CVSS v3.1](https://www.first.org/cvss/v3.1/specification-document)
